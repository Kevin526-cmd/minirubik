#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum {
    CUBIES = 7,
    PERMUTATIONS = 5040,
    ORIENTATIONS = 729,
    STATES = PERMUTATIONS * ORIENTATIONS,
    MOVES = 9
};

typedef struct {
    uint8_t p[CUBIES], o[CUBIES];
} state_t;

static const uint8_t source[3][CUBIES] = {
    {1, 4, 2, 0, 3, 5, 6},
    {0, 1, 2, 4, 5, 6, 3},
    {0, 2, 5, 3, 1, 4, 6},
};
static const uint8_t twist[3][CUBIES] = {
    {1, 2, 0, 2, 1, 0, 0},
    {0, 0, 0, 1, 2, 1, 2},
    {0, 0, 0, 0, 0, 0, 0},
};

static state_t quarter_turn(state_t state, uint8_t face)
{
    state_t result;
    for (uint8_t i = 0; i < CUBIES; ++i) {
        uint8_t from = source[face][i];
        result.p[i] = state.p[from];
        result.o[i] = (uint8_t) ((state.o[from] + twist[face][i]) % 3U);
    }
    return result;
}

static uint32_t rank_state(const state_t *state)
{
    uint32_t p = 0, o = 0;
    for (uint8_t i = 0; i < CUBIES; ++i) {
        uint8_t smaller = 0;
        for (uint8_t j = (uint8_t) (i + 1U); j < CUBIES; ++j)
            if (state->p[j] < state->p[i])
                ++smaller;
        p = p * (CUBIES - i) + smaller;
    }
    for (uint8_t i = 0; i < 6; ++i)
        o = o * 3U + state->o[i];
    return p * ORIENTATIONS + o;
}

static void unrank_state(uint32_t rank, state_t *state)
{
    uint8_t available[CUBIES] = {0, 1, 2, 3, 4, 5, 6};
    uint32_t p = rank / ORIENTATIONS, o = rank % ORIENTATIONS, f = 720;
    uint8_t sum = 0;
    for (uint8_t i = 0; i < CUBIES; ++i) {
        uint8_t q = (uint8_t) (p / f);
        p %= f;
        state->p[i] = available[q];
        for (uint8_t j = q; j + 1U < CUBIES - i; ++j)
            available[j] = available[j + 1U];
        if (i < 5)
            f /= 6U - i;
    }
    for (uint8_t i = 6; i-- > 0;) {
        state->o[i] = (uint8_t) (o % 3U);
        sum = (uint8_t) (sum + state->o[i]);
        o /= 3U;
    }
    state->o[6] = (uint8_t) ((3U - sum % 3U) % 3U);
}

static uint16_t permutation[3][PERMUTATIONS];
static uint16_t orientation[3][ORIENTATIONS];

static void build_transitions(void)
{
    state_t state;
    for (uint16_t rank = 0; rank < PERMUTATIONS; ++rank) {
        unrank_state((uint32_t) rank * ORIENTATIONS, &state);
        for (uint8_t face = 0; face < 3; ++face) {
            state_t next = quarter_turn(state, face);
            permutation[face][rank] =
                (uint16_t) (rank_state(&next) / ORIENTATIONS);
        }
    }
    for (uint16_t rank = 0; rank < ORIENTATIONS; ++rank) {
        unrank_state(rank, &state);
        for (uint8_t face = 0; face < 3; ++face) {
            state_t next = quarter_turn(state, face);
            orientation[face][rank] =
                (uint16_t) (rank_state(&next) % ORIENTATIONS);
        }
    }
}

static uint8_t dist_p[PERMUTATIONS];
static uint8_t dist_o[ORIENTATIONS];

static void build_dist_p(void)
{
    uint16_t queue[PERMUTATIONS];
    int head = 0, tail = 0;
    memset(dist_p, 0xFF, sizeof dist_p);
    dist_p[0] = 0;
    queue[tail++] = 0;
    while (head < tail) {
        uint16_t here = queue[head++];
        for (int face = 0; face < 3; ++face) {
            uint16_t next = here;
            for (int turn = 0; turn < 3; ++turn) {
                next = permutation[face][next];
                if (dist_p[next] == UINT8_MAX) {
                    dist_p[next] = (uint8_t) (dist_p[here] + 1);
                    queue[tail++] = next;
                }
            }
        }
    }
}

static void build_dist_o(void)
{
    uint16_t queue[ORIENTATIONS];
    int head = 0, tail = 0;
    memset(dist_o, 0xFF, sizeof dist_o);
    dist_o[0] = 0;
    queue[tail++] = 0;
    while (head < tail) {
        uint16_t here = queue[head++];
        for (int face = 0; face < 3; ++face) {
            uint16_t next = here;
            for (int turn = 0; turn < 3; ++turn) {
                next = orientation[face][next];
                if (dist_o[next] == UINT8_MAX) {
                    dist_o[next] = (uint8_t) (dist_o[here] + 1);
                    queue[tail++] = next;
                }
            }
        }
    }
}

static void print_histogram(const char *name, const uint8_t *dist, int size)
{
    int count[16] = {0};
    for (int i = 0; i < size; ++i)
        count[dist[i]]++;                  
    printf("%s:", name);
    for (int d = 0; d < 16 && count[d]; ++d)
        printf(" %d", count[d]);
    printf("\n");
}

int main(void)
{
    build_transitions();
    build_dist_p();
    build_dist_o();
    print_histogram("dist_p", dist_p, PERMUTATIONS);
    print_histogram("dist_o", dist_o, ORIENTATIONS);
    return 0;
}