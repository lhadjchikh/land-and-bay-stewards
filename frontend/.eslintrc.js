module.exports = {
  extends: [
    'react-app',
    'react-app/jest',
  ],
  overrides: [
    {
      // For E2E tests that need conditional expects
      files: ['src/tests/e2e/**/*.{js,jsx,ts,tsx}'],
      rules: {
        'jest/no-conditional-expect': 'off'
      }
    }
  ]
};