// jest-dom adds custom jest matchers for asserting on DOM nodes.
// allows you to do things like:
// expect(element).toHaveTextContent(/react/i)
// learn more: https://github.com/testing-library/jest-dom
import '@testing-library/jest-dom';

// Mock fetch globally
global.fetch = jest.fn() as jest.Mock;

// Helper to reset mocks
beforeEach(() => {
  (global.fetch as jest.Mock).mockClear();
});
