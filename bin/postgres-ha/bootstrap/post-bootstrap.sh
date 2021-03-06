#!/bin/bash

# Copyright 2019 - 2020 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export PGHOST="/tmp"

source /opt/cpm/bin/common/common_lib.sh
enable_debugging

echo_info "postgres-ha post-bootstrap starting"

# Run either a custom or the defaul setup.sql file
if [[ -f "/pgconf/setup.sql" ]]
then
    echo_info "Using custom setup.sql"
    cp "/pgconf/setup.sql" "/tmp"
else
    echo_info "Using default setup.sql"
    cp "/opt/cpm/bin/sql/setup.sql" "/tmp"
fi

echo_info "Running setup.sql file"
envsubst < /tmp/setup.sql | psql -f -

# If there are any tablespaces, create them as a convenience to the user, both
# the directories and the PostgreSQL objects
source /opt/cpm/bin/common/pgha-tablespaces.sh
tablespaces_create_postgresql_objects "${PGHA_USER}"

# Run audit.sql file if exists
if [[ -f "/pgconf/audit.sql" ]]
then
    echo_info "Running custom audit.sql file"
    psql < "/pgconf/audit.sql"
fi

# Apply enhancement modules
echo_info "Applying enahncement modules"
for module in /opt/cpm/bin/modules/*.sh
do
    echo_info "Applying module ${module}"
    source "${module}"
done

echo_info "postgres-ha post-bootstrap complete"
