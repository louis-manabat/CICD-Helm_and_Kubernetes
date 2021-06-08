#!/usr/bin/env bash
npm install
npm start &
npx wait-on $ENDPOINT
npm run test-e2e
