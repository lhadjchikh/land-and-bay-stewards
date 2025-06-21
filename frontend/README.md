# Coalition Builder Frontend

[![TypeScript Type Check](https://github.com/lhadjchikh/coalition-builder/actions/workflows/ts-typecheck.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/ts-typecheck.yml)
[![JavaScript & TypeScript Linting](https://github.com/lhadjchikh/coalition-builder/actions/workflows/js-lint.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/js-lint.yml)
[![Frontend Tests](https://github.com/lhadjchikh/coalition-builder/actions/workflows/frontend-tests.yml/badge.svg)](https://github.com/lhadjchikh/coalition-builder/actions/workflows/frontend-tests.yml)

This is the frontend for Coalition Builder. It's a React application with TypeScript
that interacts with the Django backend API.

## 📚 Documentation

**For complete documentation, visit: [your-org.github.io/coalition-builder](https://your-org.github.io/coalition-builder/)**

Quick links:

- [Frontend Development Guide](../docs/development/frontend.md)
- [Development Setup](../docs/development/setup.md)

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app) and has been
migrated to TypeScript.

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page will reload when you make changes.\
You may also see any lint errors in the console.

### Testing

#### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more
information.

#### `npm run test:ci`

Runs all tests except the E2E tests in non-watch mode. This is used by the CI pipeline.

#### `npm run test:e2e`

Runs only the E2E tests that require the backend to be running. These tests verify the integration between frontend and
backend.

## Test Structure

- `src/__tests__`: Unit tests for components
- `src/tests/integration`: Integration tests with mocked API
- `src/tests/e2e`: End-to-end tests with the real backend

See `src/tests/README.md` for more information on running tests.

## Code Quality

### TypeScript

This project uses TypeScript for type safety. You can run the type checker with:

```bash
npm run typecheck   # Check for type errors
```

### Linting

This project uses ESLint for code quality. You can run the linter with:

```bash
npm run lint        # Check for linting errors
npm run lint:fix    # Fix automatically fixable errors
```

The linting configuration extends the standard Create React App rules and includes Jest rules. E2E tests have some rules
relaxed due to their specific testing needs.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can't go back!**

If you aren't satisfied with the build tool and configuration choices, you can `eject` at any time. This command will
remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right
into your project so you have full control over them. All of the commands except `eject` will still work, but they will
point to the copied scripts so you can tweak them. At this point you're on your own.

You don't have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you
shouldn't feel obligated to use this feature. However we understand that this tool wouldn't be useful if you couldn't
customize it when you are ready for it.

## Learn More

You can learn more in the
[Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

To learn TypeScript, check out the [TypeScript documentation](https://www.typescriptlang.org/docs/).

### Code Splitting

This section has moved here:
[https://facebook.github.io/create-react-app/docs/code-splitting](https://facebook.github.io/create-react-app/docs/code-splitting)

### Analyzing the Bundle Size

This section has moved here:
[https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size](https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size)

### Making a Progressive Web App

This section has moved here:
[https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app](https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app)

### Advanced Configuration

This section has moved here:
[https://facebook.github.io/create-react-app/docs/advanced-configuration](https://facebook.github.io/create-react-app/docs/advanced-configuration)

### Deployment

This section has moved here:
[https://facebook.github.io/create-react-app/docs/deployment](https://facebook.github.io/create-react-app/docs/deployment)
