// SecureCity AI — least-privilege MongoDB application user.
//
// ai_engine/cv_engine currently connect using the cluster's root
// credentials (MONGO_ROOT_USER/MONGO_ROOT_PASSWORD) — full admin rights
// for two services that only ever need readWrite on one database. This
// creates a scoped `securecity_ml_app` user instead.
//
// Runs automatically via docker-entrypoint-initdb.d on a FRESH mongodb
// container (empty data volume) — the official mongo image only executes
// these scripts the very first time it initializes an empty data
// directory. On an EXISTING deployment with a populated `mongo_data`
// volume, this script will NOT run automatically; create the user
// manually once via:
//
//   docker compose exec mongodb mongosh -u <root_user> -p <root_password> \
//     --authenticationDatabase admin <db_name> --eval '
//       db.createUser({
//         user: "<app_user>", pwd: "<app_password>",
//         roles: [{ role: "readWrite", db: "<db_name>" }]
//       })'

const dbName = process.env.MONGO_INITDB_DATABASE || "securecity_ml";
const appUser = process.env.MONGO_APP_USER || "securecity_ml_app";
const appPassword = process.env.MONGO_APP_PASSWORD;

if (!appPassword) {
  throw new Error(
    "MONGO_APP_PASSWORD is not set — cannot create the securecity_ml_app user."
  );
}

const targetDb = db.getSiblingDB(dbName);

targetDb.createUser({
  user: appUser,
  pwd: appPassword,
  roles: [{ role: "readWrite", db: dbName }],
});

print(`[init-app-user] Created least-privilege user '${appUser}' with readWrite on '${dbName}'.`);
