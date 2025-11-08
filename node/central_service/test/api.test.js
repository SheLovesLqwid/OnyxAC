/*
    made by TheOGDev Founder/CEO of OGDev Studios LLC
    OnyxAC - core script / module / resource
    Description: OnyxAC is an open-source FiveM anti-cheat and admin toolset. Feel free to use,
    rebrand, modify, and redistribute this project. Attribution is appreciated but not required.
    If you redistribute or modify, please include credit to TheOGDev and link to:
    https://github.com/SheLovesLqwid
    WARNING: Attempting to claim this project as your own is discouraged. This file header must
    remain at the top of every file in this repository.
*/

const request = require('supertest');
const app = require('../index');

describe('OnyxAC Central Service API', () => {
    describe('GET /health', () => {
        it('should return health status', async () => {
            const res = await request(app)
                .get('/health')
                .expect(200);
            
            expect(res.body).toHaveProperty('status', 'healthy');
            expect(res.body).toHaveProperty('timestamp');
            expect(res.body).toHaveProperty('uptime');
        });
    });

    describe('POST /api/check', () => {
        it('should require API key', async () => {
            await request(app)
                .post('/api/check')
                .send({ playerIdentifier: 'steam:110000100000000' })
                .expect(401);
        });

        it('should check player ban status with valid API key', async () => {
            const res = await request(app)
                .post('/api/check')
                .set('x-api-key', process.env.API_KEY || 'test-api-key')
                .send({ playerIdentifier: 'steam:110000100000000' })
                .expect(200);
            
            expect(res.body).toHaveProperty('banned');
        });

        it('should validate input data', async () => {
            await request(app)
                .post('/api/check')
                .set('x-api-key', process.env.API_KEY || 'test-api-key')
                .send({ invalidField: 'test' })
                .expect(400);
        });
    });

    describe('GET /api/stats', () => {
        it('should require API key', async () => {
            await request(app)
                .get('/api/stats')
                .expect(401);
        });

        it('should return statistics with valid API key', async () => {
            const res = await request(app)
                .get('/api/stats')
                .set('x-api-key', process.env.API_KEY || 'test-api-key')
                .expect(200);
            
            expect(res.body).toHaveProperty('totalBans');
            expect(res.body).toHaveProperty('activeBans');
            expect(res.body).toHaveProperty('connectedServers');
        });
    });

    describe('Rate Limiting', () => {
        it('should rate limit requests', async () => {
            const requests = [];
            for (let i = 0; i < 105; i++) {
                requests.push(
                    request(app)
                        .get('/health')
                );
            }
            
            const responses = await Promise.all(requests);
            const rateLimited = responses.some(res => res.status === 429);
            expect(rateLimited).toBe(true);
        }, 10000);
    });
});
