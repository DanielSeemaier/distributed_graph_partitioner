#include <mpi.h>
#include <parhip_interface.h>

#include <chrono>

#include "common.h"

using namespace driver;

int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    auto config = parse_arguments(argc, argv);
    auto graph = generate_graph(config);
    const std::size_t num_nodes =
        graph.vertex_range.second - graph.vertex_range.first;

    auto vtxdist = kagen::BuildVertexDistribution<unsigned long long>(
        graph, MPI_UNSIGNED_LONG_LONG, MPI_COMM_WORLD);
    auto [xadj, adjncy] = kagen::BuildCSR<unsigned long long>(std::move(graph));

    int k = config.k;
    MPI_Comm comm = MPI_COMM_WORLD;
    std::vector<idxtype> partition(num_nodes);
    double imbalance = 0.03;
    int cut;

    int rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    for (int iter = 0; iter < config.repetitions; ++iter) {
        int mode = config.eco ? ECOSOCIAL : FASTSOCIAL;

        auto start = std::chrono::steady_clock::now();
        ParHIPPartitionKWay(vtxdist.data(), xadj.data(), adjncy.data(), nullptr,
                            nullptr, &k, &imbalance, false, iter, mode, &cut,
                            partition.data(), &comm);
        auto end = std::chrono::steady_clock::now();

        if (rank == 0) {
            auto time = std::chrono::duration_cast<std::chrono::milliseconds>(
                            end - start)
                            .count();
            std::cout << "RESULT cut=" << cut << " time=" << 1.0 * time / 1000
                      << std::endl;
        }
    }

    MPI_Finalize();
}