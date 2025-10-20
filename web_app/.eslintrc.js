module.exports = {
    env: {
        es2021: true,
        node: true,
        jest: true
    },
    extends: ['eslint:recommended'],
    parserOptions: {
        ecmaVersion: 12,
        sourceType: 'module'
    },
    rules: {
        'no-unused-vars': 'error',
        'no-console': 'off',
        'prefer-const': 'error',
        'no-var': 'error'
    }
};