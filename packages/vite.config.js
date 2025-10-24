import { defineConfig } from 'vite'

export default defineConfig({
    root: 'web',
    build: {
        outDir: '../web-dist',
        emptyOutDir: true
    },
    server: {
        port: 3001,
        proxy: {
            '/api': {
                target: 'http://localhost:3000',
                changeOrigin: true
            },
            '/health': {
                target: 'http://localhost:3000',
                changeOrigin: true
            }
        }
    },
    base: '/',
    publicDir: 'public'
})