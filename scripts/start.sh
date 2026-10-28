#!/bin/sh
set -x

# Replace the statically built BUILT_NEXT_PUBLIC_WEBAPP_URL with run-time NEXT_PUBLIC_WEBAPP_URL
# NOTE: if these values are the same, this will be skipped.
scripts/replace-placeholder.sh "$BUILT_NEXT_PUBLIC_WEBAPP_URL" "$NEXT_PUBLIC_WEBAPP_URL"

# La contraseña llega aparte (DATABASE_PASSWORD) y se codifica para la URL,
# así funciona con cualquier símbolo. Las URLs traen __DB_PASSWORD__ en su lugar.
# Sin xtrace en este bloque para que la contraseña no salga en los logs.
set +x
if [ -n "$DATABASE_PASSWORD" ]; then
  DATABASE_URL=$(node -e 'const e=encodeURIComponent(process.env.DATABASE_PASSWORD).replace(/[!'"'"'()*]/g,c=>"%"+c.charCodeAt(0).toString(16).toUpperCase());process.stdout.write(process.argv[1].split("__DB_PASSWORD__").join(e))' "$DATABASE_URL")
  DATABASE_DIRECT_URL=$(node -e 'const e=encodeURIComponent(process.env.DATABASE_PASSWORD).replace(/[!'"'"'()*]/g,c=>"%"+c.charCodeAt(0).toString(16).toUpperCase());process.stdout.write(process.argv[1].split("__DB_PASSWORD__").join(e))' "$DATABASE_DIRECT_URL")
  export DATABASE_URL DATABASE_DIRECT_URL
  unset DATABASE_PASSWORD
fi
set -x

scripts/wait-for-it.sh ${DATABASE_HOST} -- echo "database is up"
npx prisma migrate deploy --schema /calcom/packages/prisma/schema.prisma
npx ts-node --transpile-only /calcom/scripts/seed-app-store.ts
yarn start
