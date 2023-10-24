AZURE_LOCATION="eastus"
LOG_ANALYTICS_WRKSPC_NAME=""
LOG_ANALYTICS_WRKSPC_SUBSCRIPTION_ID=""
LOG_ANALYTICS_WRKSPC_RESOURCE_GROUP=""
LOG_ANALYTICS_WRKSPC_RESOURCE_TAGS="{ \"Department\": \"RESEARCH\", \"CostCentre\": \"DEV\", \"DeleteNightly\": \"true\",  \"DeleteWeekly\": \"true\", \"Architecture\": \"LOG-ANALYTICS\"}"

PGSQL_NAME=""
PGSQL_SUBSCRIPTION_ID=""
PGSQL_RESOURCE_GROUP=""
PGSQL_RESOURCE_TAGS="{ \"Department\": \"RESEARCH\", \"CostCentre\": \"DEV\", \"DeleteNightly\": \"false\",  \"DeleteWeekly\": \"false\", \"Architecture\": \"PGSQL\"}"

APP_SERVICE_NAME=""
APP_SERVICE_RESOURCE_GROUP=""
APP_SERVICE_RESOURCE_TAGS="{ \"Department\": \"RESEARCH\", \"CostCentre\": \"DEV\", \"DeleteNightly\": \"false\",  \"DeleteWeekly\": \"false\", \"Architecture\": \"APP-SERVICE\"}"

DBA_GROUP_NAME="PGSQL-ADMINS"
DBA_GROUP_ID=`az ad group show --group "${DBA_GROUP_NAME}" --query '[id]' -o tsv`

DB_NAME="tododb"
DB_NAME_STAGING="stagingtododb"

DB_USER_MI_NAME="todoapi"
DB_USER_MI_STAGING_NAME="stagingtodoapi"
clientIPAddress=`dig +short myip.opendns.com @resolver1.opendns.com.`

az deployment sub create \
    --l $AZURE_LOCATION \
    --template-file ./templates/resource_groups.bicep \
    --parameters location="${AZURE_LOCATION}" \
                 appServiceRG="${APP_SERVICE_RESOURCE_GROUP}" \
                 appServiceTags="${APP_SERVICE_RESOURCE_TAGS}" \
                 pgsqlSubscriptionId="${PGSQL_SUBSCRIPTION_ID}" \
                 pgsqlRG="${PGSQL_RESOURCE_GROUP}" \
                 pgsqlTags="${PGSQL_RESOURCE_TAGS}" \
                 logAnalyticsSubscriptionId="${LOG_ANALYTICS_WRKSPC_SUBSCRIPTION_ID}" \
                 logAnalyticsRG="${LOG_ANALYTICS_WRKSPC_RESOURCE_GROUP}" \
                 logAnalyticsTags="${LOG_ANALYTICS_WRKSPC_RESOURCE_TAGS}"

az deployment group create \
    --resource-group $APP_SERVICE_RESOURCE_GROUP \
    --template-file ./templates/main.bicep \
    --parameters appServiceName="${APP_SERVICE_NAME}" \
                 appServicePort=443 \
                 appServiceTags="${APP_SERVICE_RESOURCE_TAGS}" \
                 pgsqlName="${PGSQL_NAME}" \
                 pgsqlAADAdminGroupName="${DBA_GROUP_NAME}" \
                 pgsqlAADAdminGroupObjectId="${DBA_GROUP_ID}" \
                 pgsqlDbName="${DB_NAME}" \
                 pgsqlStagingDbName="${DB_NAME_STAGING}" \
                 pgsqlSubscriptionId="${PGSQL_SUBSCRIPTION_ID}" \
                 pgsqlRG="${PGSQL_RESOURCE_GROUP}" \
                 pgsqlTags="${PGSQL_RESOURCE_TAGS}" \
                 logAnalyticsName="${LOG_ANALYTICS_WRKSPC_NAME}" \
                 logAnalyticsSubscriptionId="${LOG_ANALYTICS_WRKSPC_SUBSCRIPTION_ID}" \
                 logAnalyticsRG="${LOG_ANALYTICS_WRKSPC_RESOURCE_GROUP}" \
                 logAnalyticsTags="${LOG_ANALYTICS_WRKSPC_RESOURCE_TAGS}" \
                 healthCheckPath="" \
                 dbUserName="${DB_USER_MI_NAME}" \
                 dbStagingUserName="${DB_USER_MI_STAGING_NAME}" \
                 deploymentClientIPAddress="${clientIPAddress}" \
                 location="${AZURE_LOCATION}"

export PGPASSWORD=`az account get-access-token --resource-type oss-rdbms --query "[accessToken]" --output tsv`

./create_aad_db.sh -s "${PGSQL_NAME}" -d "${DB_NAME}" -a "${DBA_GROUP_NAME}"
./create_aad_db.sh -s "${PGSQL_NAME}" -d "${DB_NAME_STAGING}" -a "${DBA_GROUP_NAME}"
psql --set=sslmode=require -h ${PGSQL_NAME}.postgres.database.azure.com -p 5432 -d "${DB_NAME}" -U "${DBA_GROUP_NAME}" --file=./create_todo_table.sql
psql --set=sslmode=require -h ${PGSQL_NAME}.postgres.database.azure.com -p 5432 -d "${DB_NAME_STAGING}" -U "${DBA_GROUP_NAME}" --file=./create_todo_table.sql

DB_APP_USER_APP_ID=`az ad sp list --display-name $APP_SERVICE_NAME --query "[?displayName=='${APP_SERVICE_NAME}'].appId" --out tsv`
DB_APP_USER_STAGING_APP_ID=`az ad sp list --display-name "${APP_SERVICE_NAME}/slots/staging" --query "[?displayName=='${APP_SERVICE_NAME}/slots/staging'].appId" --out tsv`
    

./create_aad_pgsql_user.sh -s "${PGSQL_NAME}" \
                          -d "${DB_NAME}" \
                          -a "${DBA_GROUP_NAME}" \
                          -n "${DB_USER_MI_NAME}" \
                          -o "${DB_APP_USER_APP_ID}"

./create_aad_pgsql_user.sh -s "${PGSQL_NAME}" \
                           -d "${DB_NAME_STAGING}" \
                           -a "${DBA_GROUP_NAME}" \
                           -n "${DB_USER_MI_STAGING_NAME}" \
                           -o "${DB_APP_USER_STAGING_APP_ID}"

cd ../todo
./mvnw clean
./mvnw -B package

az webapp deploy --resource-group $APP_SERVICE_RESOURCE_GROUP --name $APP_SERVICE_NAME --slot staging --type jar --src-path ./target/todo-0.0.1.jar
