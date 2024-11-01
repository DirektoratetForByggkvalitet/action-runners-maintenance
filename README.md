# action-runners-maintenance

Runs maintenance scripts on self-hosted Github action runners.

In order to work, each individual action runner needs to have a unique label (ie. mac-1, mac-2 etc). We presume that all the runners are similiar computers; Apple Silicon Mac minis.

The labels are then listed in [maintenance.yml](.github/workflows/maintenance.yml) as the array strategy.matrix.runner. This will lead to the job running in parallel on each runner.

The actual maintenance done can be specified in the steps. In this instance, we run a Docker system prune and Homebrew upgrades.

We also added a Brewfile, enabling us to ensure that the same Homebrew software is installed and maintained on all runners.
