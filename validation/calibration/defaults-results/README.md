# Defaults study: results

Produced by GitHub Actions run 36099112308 (workflow `defaults-study.yml`,
commit 505def2) from the pre-registration committed in 61a915f
(`../DEFAULTS.md`). The only change between the two commits pins glmnet in the
workflow: the first dispatch (run 36097846926) stopped at the version check,
before any replication, because glmnet 5.1 reached the package mirror between
the setup job and the shards.

* `REPORT.md`: decisions under the rules of `DEFAULTS.md`, and all cell means.
* `decisions.rds`: the comparisons (units, point estimates, bootstrap
  intervals, per-stratum differences).
* `raw.rds`: one row per replication and variant for every cell.
* `session.txt`: R session of shard 1 (all shards used identical versions).

The fixed designs, Theta and Z (`setup.rds`, 7.8 MB, md5
e0eb413abe06d2afcc8becdc4a87aa8a) are attached to the GitHub release v2.0.0.
