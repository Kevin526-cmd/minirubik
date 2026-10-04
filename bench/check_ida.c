/*
 * Host correctness gates H1-H4 and worst-case search for IDA_ripes.c.
 *
 * Build from the repository root:
 *   gcc -O2 -o check_ida bench/check_ida.c
 *   ./check_ida            # H1, H2, H4, distance-11 worst case (seconds)
 *   ./check_ida --full     # also H3 over all 3,674,160 states (minutes)
 *
 * The oracle is an exact BFS over (P, O) pairs, built independently of
 * the search, with the same move set (R, B, D quarter/half/inverse turns).
 */
#define main ida_main
#include "../IDA_ripes.c"
#undef main

#include <time.h>

static uint8_t exact[STATES];   /* exact distance, 0xFF = unvisited */
static uint32_t bfs_queue[STATES];

static void build_oracle(void)
{
    uint32_t head = 0, tail = 0;
    memset(exact, 0xFF, sizeof exact);
    exact[0] = 0;
    bfs_queue[tail++] = 0;
    while (head < tail) {
        uint32_t here = bfs_queue[head++];
        uint16_t P = (uint16_t) (here / ORIENTATIONS);
        uint16_t O = (uint16_t) (here % ORIENTATIONS);
        for (int face = 0; face < 3; ++face) {
            uint16_t nP = P, nO = O;
            for (int turn = 0; turn < 3; ++turn) {
                nP = permutation[face][nP];
                nO = orientation[face][nO];
                uint32_t next = (uint32_t) nP * ORIENTATIONS + nO;
                if (exact[next] == UINT8_MAX) {
                    exact[next] = (uint8_t) (exact[here] + 1);
                    bfs_queue[tail++] = next;
                }
            }
        }
    }
}

static int failures;
#define CHECK(cond, ...)                         \
    do {                                         \
        if (!(cond)) {                           \
            if (failures++ < 10) {               \
                printf("  FAIL: " __VA_ARGS__);  \
                printf("\n");                    \
            }                                    \
        }                                        \
    } while (0)

/* Apply path[0..n-1] to (P, O) and report whether it reaches solved. */
static int path_solves(uint16_t P, uint16_t O, int n)
{
    for (int k = 0; k < n; ++k) {
        int face = path[k] / 3, turns = path[k] % 3 + 1;
        for (int t = 0; t < turns; ++t) {
            P = permutation[face][P];
            O = orientation[face][O];
        }
    }
    return P == 0 && O == 0;
}

static int is_bijection(const uint16_t *row, int size)
{
    static uint8_t seen[PERMUTATIONS];
    memset(seen, 0, sizeof seen);
    for (int i = 0; i < size; ++i) {
        if (row[i] >= size || seen[row[i]])
            return 0;
        seen[row[i]] = 1;
    }
    return 1;
}

static void gate_h2(void)
{
    int before = failures;
    int max_p = 0, max_o = 0;
    printf("H2: tables fully populated, maxima and solved entries\n");
    for (int i = 0; i < PERMUTATIONS; ++i) {
        CHECK(dist_p[i] != UINT8_MAX, "dist_p[%d] unvisited", i);
        if (dist_p[i] > max_p) max_p = dist_p[i];
    }
    for (int i = 0; i < ORIENTATIONS; ++i) {
        CHECK(dist_o[i] != UINT8_MAX, "dist_o[%d] unvisited", i);
        if (dist_o[i] > max_o) max_o = dist_o[i];
    }
    CHECK(dist_p[0] == 0, "dist_p[0] = %d", dist_p[0]);
    CHECK(dist_o[0] == 0, "dist_o[0] = %d", dist_o[0]);
    CHECK(max_p == 7, "max dist_p = %d, expected 7", max_p);
    CHECK(max_o == 6, "max dist_o = %d, expected 6", max_o);
    for (int f = 0; f < 3; ++f) {
        CHECK(is_bijection(permutation[f], PERMUTATIONS),
              "permutation[%d] is not a bijection", f);
        CHECK(is_bijection(orientation[f], ORIENTATIONS),
              "orientation[%d] is not a bijection", f);
    }
    printf("  max dist_p = %d, max dist_o = %d, solved entries = %d, %d\n",
           max_p, max_o, dist_p[0], dist_o[0]);
    printf("  %s\n", failures == before ? "PASS" : "FAILED");
}

static void gate_oracle(int count[16])
{
    int diameter = 0;
    long total = 0;
    for (uint32_t s = 0; s < STATES; ++s) {
        CHECK(exact[s] != UINT8_MAX, "oracle state %u unvisited", s);
        count[exact[s]]++;
        total++;
        if (exact[s] > diameter) diameter = exact[s];
    }
    printf("Oracle: %ld states, diameter %d\n  levels:", total, diameter);
    for (int d = 0; d <= diameter; ++d)
        printf(" %d", count[d]);
    printf("\n");
}

static void gate_h1(void)
{
    int before = failures;
    long tight = 0;
    printf("H1: h(s) <= d(s) over all %d states\n", STATES);
    for (uint32_t s = 0; s < STATES; ++s) {
        uint16_t P = (uint16_t) (s / ORIENTATIONS);
        uint16_t O = (uint16_t) (s % ORIENTATIONS);
        int h = heuristic(P, O);
        CHECK(h <= exact[s], "state %u: h = %d > d = %d", s, h, exact[s]);
        if (h == exact[s]) tight++;
    }
    printf("  h == d on %ld states (%.1f%%)\n", tight, 100.0 * tight / STATES);
    printf("  %s\n", failures == before ? "PASS" : "FAILED");
}

/* Solve every state with exact distance in [lo, hi]; check length and path. */
static void run_search(int lo, int hi, const char *label)
{
    int before = failures;
    long solved = 0, max_nodes = 0, sum_nodes = 0;
    uint32_t worst = 0;
    clock_t start = clock();
    printf("%s\n", label);
    for (uint32_t s = 0; s < STATES; ++s) {
        if (exact[s] < lo || exact[s] > hi)
            continue;
        uint16_t P = (uint16_t) (s / ORIENTATIONS);
        uint16_t O = (uint16_t) (s % ORIENTATIONS);
        nodes = 0;
        int n = solve(P, O);
        CHECK(n == exact[s], "state %u: search length %d, exact %d", s, n,
              exact[s]);
        CHECK(path_solves(P, O, n), "state %u: path does not solve", s);
        solved++;
        sum_nodes += nodes;
        if (nodes > max_nodes) {
            max_nodes = nodes;
            worst = s;
        }
    }
    double secs = (double) (clock() - start) / CLOCKS_PER_SEC;
    state_t st;
    unrank_state(worst, &st);
    char text[15];
    for (int i = 0; i < CUBIES; ++i) {
        text[i] = (char) ('1' + st.p[i]);
        text[i + CUBIES] = (char) ('1' + st.o[i]);
    }
    text[14] = '\0';
    printf("  states %ld, mean nodes %.0f, max nodes %ld at %s (d = %d)\n",
           solved, (double) sum_nodes / solved, max_nodes, text, exact[worst]);
    printf("  wall-clock %.1f s\n", secs);
    printf("  %s\n", failures == before ? "PASS" : "FAILED");
}

int main(int argc, char **argv)
{
    int full = argc > 1 && !strcmp(argv[1], "--full");
    int count[16] = {0};

    build_transitions();
    build_dist_p();
    build_dist_o();
    build_oracle();

    gate_oracle(count);
    gate_h1();
    gate_h2();
    printf("H3: search length == exact distance\n");
    if (full)
        run_search(0, 11, "  all states");
    else
        printf("  skipped (run with --full)\n");
    run_search(11, 11, "Worst case over the distance-11 states");
    printf("H4: no packed tables yet (byte tables only) -- not applicable\n");

    printf("\n%s (%d failure%s)\n", failures ? "FAILED" : "ALL PASSED",
           failures, failures == 1 ? "" : "s");
    return failures != 0;
}
