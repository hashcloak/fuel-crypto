# Fuel Webauthn Wallet

Simple webapp that has a connection with the Fuel blockchain (Wallet in browser and predicate loaded) & webauthn integrated.

## App Functionality

This small app has the following functionality:

- user can click on Register, this does registration with WebAuthn and creates a predicate using the public key from WebAuthn
- user can click on Authentication, this only does authentication with WebAuthn for the moment.

TODO:
- send funds using Authentication with WebAuthn, which results in a signature, which will be validated by the predicate and makes the transaction valid

Expected workings:
- click on Register: should give a popup in browser for registration. Successfully going through these steps should give a message in the console "Registration successful", print the pubkey and create the predicate based on the pubkey
- click on Authenticate when registered: should give a popup for authentication. Successfully going through these steps should give a message in the console "Authentication successful" 
- when Registration or Authentication fails it should give that as an error in the console


## Codebase explanation + instructions

The codebase consists of 3 parts:
- predicate; this is where the Sway predicate lives. It is a simple example taken from [documentation](https://fuellabs.github.io/fuels-ts/guide/predicates/) for the moment
- server; this is where the calls to webauthn live. Absolutely not production ready, it even has some hardcoded `expectedOrigin`s. This does registration and authentication, following an example repo
- frontend; the visual part that ties it all together. Calls both the server that does WebAuthn stuff & creates the predicate that is the burner wallet


### 1. Predicate code

Reference [here](https://fuellabs.github.io/fuels-ts/guide/predicates/). Build the predicate:

```
cd predicate
forc build
```

Then generate the necessary files for the frontend based on the predicate:
```
cd ../frontend
npm install
npx fuels typegen -i ../**/**/*-abi.json  -o ./src/types --predicate
```

Make sure that in `frontend/src/types/index.ts` only 1 line similar to:
`
export { PredicateAbi__factory } from './factories/PredicateAbi__factory';
`
exists. Remove any redundant lines. 

### 2. WebAuthn Server

Example code: https://github.com/MasterKale/SimpleWebAuthn/tree/master/example

This server code expects the frontend to run on port 3000. If this is not the case, change the hardcoded `expectedOrigin` in `server/src/index.ts`. 

```
cd server
npm install
npm start
```

### 3. Frontend

Tutorial: https://fuelbook.fuel.network/master/quickstart/frontend.html

Needs to run on fuels >= 0.42.0.

Make sure that the typings for the predicate have been generated and that in `frontend/src/types/index.ts` only 1 `PredicateAbi__factory` is exported. 
Furthermore, the server must be running on 127.0.0.1:8000, if it is somewhere else, this has to be adjusted in `frontend/package.json`, specifically `"proxy": "http://127.0.0.1:8000"`. 

Open the app in a browser where the Fuel wallet extension has been added and WebAuthn is supported. Open the console in the Developer Tools to see additional messages. 

```
cd frontend
# npm install <-- this has probably already been run in a previous step
npm start
```
