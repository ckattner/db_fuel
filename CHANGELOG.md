
# 2.1.0 (May 19th, 2021)

Additions:

* Added keys_register to all db_fuel/active_record jobs.

# 2.0.1 (March 18th, 2021)

Changes:

* Updated attribute_renderer_set to avoid an evaluation time issue with acts_as_hashable.

# 2.0.0 (March 16th, 2021)

New Jobs:
* db_fuel/active_record/upsert
* db_fuel/active_record/update_all

Changes:
* db_fuel/active_record/update now only updates a single record. Use db_fuel/active_record/update_all to update multiple records at a time.

# 1.1.0 (Decmeber 1st, 2020)

New Jobs:

* db_fuel/active_record/find_or_insert
* db_fuel/active_record/insert
* db_fuel/active_record/update

# 1.0.0 (November 18th, 2020)

Initial implementation.  Includes jobs:

* db_fuel/dbee/query
* db_fuel/dbee/range

# 0.0.1

Shell
