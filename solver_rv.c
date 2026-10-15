#include <stdint.h>
#include "tables.h"

static const char input[15] = "21345671111111";

static int heuristic(uint16_t P, uint16_t O, uint8_t ca, uint8_t cb)
{
    int a = ca & 3;
    int b = cb & 3;
    int index = (P << 3) + P + (a << 1) + a + b;
    int h_po = dist_po[index];
    int h_o = dist_o[O];
    return h_po > h_o ? h_po : h_o;
}

static uint16_t stP[16], stO[16];
static uint8_t stA[16], stB[16];
static uint8_t cur_face[16];
static uint8_t cur_turn[16];
static uint8_t path_face[16];
static uint8_t path_turn[16];

static int search_iter(uint16_t P, uint16_t O, uint8_t ca, uint8_t cb, int bound, int *next_bound)
{
    int d = 0;
    int min_f = 99;
    stP[0] = P; stO[0] = O; stA[0] = ca; stB[0] = cb;
    cur_face[0] = 0; cur_turn[0] = 0;
    if (P == 0 && O == 0) return 0;

    while (d >= 0) {
        int face = cur_face[d];
        if (face == 3) {                        
            d--;
            continue;
        }
        int turn = cur_turn[d];
        if (turn == 0 && d > 0 && face == path_face[d - 1]) {
            cur_face[d] = (uint8_t)(face + 1);
            continue;
        }

       
        if (turn == 2) {
            cur_face[d] = (uint8_t)(face + 1);
            cur_turn[d] = 0;
        } else {
            cur_turn[d] = (uint8_t)(turn + 1);
        }

        if (turn == 0) {
            stP[d + 1] = permutation[face][stP[d]];
            stO[d + 1] = orientation[face][stO[d]];
            stA[d + 1] = cubie_move[face][stA[d]];
            stB[d + 1] = cubie_move[face][stB[d]];
        } else {
            stP[d + 1] = permutation[face][stP[d + 1]];
            stO[d + 1] = orientation[face][stO[d + 1]];
            stA[d + 1] = cubie_move[face][stA[d + 1]];
            stB[d + 1] = cubie_move[face][stB[d + 1]];
        }

        int f = d + 1 + heuristic(stP[d + 1], stO[d + 1], stA[d + 1], stB[d + 1]);
        if (f > bound) {
            if (f < min_f) min_f = f;
            continue;
        }
        path_face[d] = (uint8_t) face;
        path_turn[d] = (uint8_t) turn;
        if (stP[d + 1] == 0 && stO[d + 1] == 0)
            return d + 1;
        d++;
        cur_face[d] = 0;
        cur_turn[d] = 0;
    }
    *next_bound = min_f;
    return -1;
}

static int solve(uint16_t P, uint16_t O, uint8_t ca, uint8_t cb)
{
    int bound = heuristic(P, O, ca, cb);

    for (;;) {
        int next_bound;
        int n = search_iter(P, O, ca, cb, bound, &next_bound);
        if (n >= 0) return n;
        bound = next_bound;
    }
}

static void parse(uint16_t *P, uint16_t *O, uint8_t *ca, uint8_t *cb)
{
    uint8_t p[7], o[7];
    for (int i = 0; i < 7; ++i) {
        p[i] = (uint8_t)(input[i] - '1');
        o[i] = (uint8_t)(input[i + 7] - '1');
        if (p[i] == 0) *ca = (uint8_t)((i << 2) + o[i]);
        if (p[i] == 1) *cb = (uint8_t)((i << 2) + o[i]);
    }

    uint16_t oo = 0;
    for (int i = 0; i < 6; ++i)
        oo = (uint16_t)((oo << 1) + oo + o[i]); 
    *O = oo;
    
    static const uint16_t weight[7] = {720, 120, 24, 6, 2, 1, 0};
    
    uint16_t pp = 0;
    for (int i = 0; i < 7; ++i) {
        for (int j = i + 1; j < 7; ++j)
            if (p[j] < p[i]) 
                pp = (uint16_t)(pp + weight[i]);
    }
    *P = pp;
}

static int result_len;
static int result_ok;

int main(void)
{
    uint16_t P, O;
    uint8_t ca = 0, cb = 0;
    parse(&P, &O, &ca, &cb);

    result_len = solve(P, O, ca, cb);

    uint16_t vP = P, vO = O;
    for (int k = 0; k < result_len; ++k) {
        int face = path_face[k];
        for (int t = 0; t <= path_turn[k]; ++t) {
            vP = permutation[face][vP];
            vO = orientation[face][vO];
        }
    }
    result_ok = (vP == 0 && vO == 0);
    return result_ok ? result_len : 99;
}