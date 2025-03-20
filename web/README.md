# Frontend

Requirements:

- NodeJS 20 or later: https://nodejs.org/en/

## Configuration

The application loads a configuration file on start which lives in the [`public/`](./public/config.json) folder.
This configuration file sets the URL of the API to use.

## Quick Start

```sh
npm install # install dependencies
npm run dev # start the development environment
```

And navigate to <http://localhost:5173/>

This environment automatically reloads when files are edited.

## Build for production

```sh
npm ci # install dependencies
npm run build # build the app to the `dist/` folder
npm run start # serve the files in the `dist/` folder
```

And navigate to <http://localhost:3000/>
