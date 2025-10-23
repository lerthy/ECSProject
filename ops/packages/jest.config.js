module.exports = {
    testEnvironment: 'node',
    testMatch: ['**/api/tests/**/*.test.js'],
    collectCoverageFrom: [
        'api/**/*.js',
        '!api/tests/**',
        '!api/server.js'
    ],
    coverageDirectory: 'coverage',
    coverageReporters: ['text', 'lcov', 'html'],
    setupFilesAfterEnv: ['<rootDir>/api/tests/setup.js']
};