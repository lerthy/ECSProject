// Test setup file
process.env.NODE_ENV = 'test';

// Mock AWS X-Ray for testing
jest.mock('aws-xray-sdk-express', () => ({
    express: {
        openSegment: () => (req, res, next) => next(),
        closeSegment: () => (req, res, next) => next()
    }
}));

jest.mock('aws-xray-sdk-core', () => ({
    getSegment: () => ({
        addNewSubsegment: () => ({
            addAnnotation: () => { },
            addError: () => { },
            close: () => { }
        })
    })
}));