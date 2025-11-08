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

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const crypto = require('crypto');
const { RateLimiterMemory } = require('rate-limiter-flexible');
const winston = require('winston');
const Joi = require('joi');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'onyxac-central' },
    transports: [
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});

const rateLimiter = new RateLimiterMemory({
    keyGenerator: (req) => req.ip,
    points: 100,
    duration: 60,
});

const bans = new Map();
const servers = new Map();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.use(async (req, res, next) => {
    try {
        await rateLimiter.consume(req.ip);
        next();
    } catch (rejRes) {
        res.status(429).json({ error: 'Too many requests' });
    }
});

function validateApiKey(req, res, next) {
    const apiKey = req.headers['x-api-key'];
    const expectedKey = process.env.API_KEY;
    
    if (!apiKey || !expectedKey) {
        return res.status(401).json({ error: 'API key required' });
    }
    
    if (apiKey !== expectedKey) {
        logger.warn('Invalid API key attempt', { ip: req.ip, key: apiKey });
        return res.status(401).json({ error: 'Invalid API key' });
    }
    
    next();
}

function validateHMAC(req, res, next) {
    const signature = req.headers['x-signature'];
    const secret = process.env.HMAC_SECRET;
    
    if (!signature || !secret) {
        return res.status(401).json({ error: 'HMAC signature required' });
    }
    
    const payload = JSON.stringify(req.body);
    const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(payload)
        .digest('hex');
    
    if (signature !== expectedSignature) {
        logger.warn('Invalid HMAC signature', { ip: req.ip });
        return res.status(401).json({ error: 'Invalid signature' });
    }
    
    next();
}

const banSchema = Joi.object({
    playerIdentifier: Joi.string().required(),
    playerName: Joi.string().required(),
    adminIdentifier: Joi.string().allow(null),
    adminName: Joi.string().allow(null),
    reason: Joi.string().required(),
    expireDate: Joi.date().allow(null),
    evidence: Joi.string().allow(null),
    serverId: Joi.string().required()
});

const unbanSchema = Joi.object({
    banId: Joi.string().required(),
    serverId: Joi.string().required(),
    reason: Joi.string().allow('')
});

const checkSchema = Joi.object({
    playerIdentifier: Joi.string().required()
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        bansCount: bans.size,
        serversCount: servers.size
    });
});

app.post('/api/ban', validateApiKey, validateHMAC, async (req, res) => {
    try {
        const { error, value } = banSchema.validate(req.body);
        if (error) {
            return res.status(400).json({ error: error.details[0].message });
        }
        
        const banId = crypto.randomUUID();
        const banData = {
            id: banId,
            ...value,
            banDate: new Date(),
            isActive: true
        };
        
        bans.set(banId, banData);
        
        logger.info('Ban created', {
            banId,
            playerIdentifier: value.playerIdentifier,
            serverId: value.serverId,
            reason: value.reason
        });
        
        res.status(201).json({
            success: true,
            banId: banId,
            message: 'Ban synchronized successfully'
        });
        
    } catch (error) {
        logger.error('Error creating ban', { error: error.message, stack: error.stack });
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/unban', validateApiKey, validateHMAC, async (req, res) => {
    try {
        const { error, value } = unbanSchema.validate(req.body);
        if (error) {
            return res.status(400).json({ error: error.details[0].message });
        }
        
        const ban = bans.get(value.banId);
        if (!ban) {
            return res.status(404).json({ error: 'Ban not found' });
        }
        
        ban.isActive = false;
        ban.unbanDate = new Date();
        ban.unbanReason = value.reason;
        ban.unbanServerId = value.serverId;
        
        logger.info('Ban removed', {
            banId: value.banId,
            serverId: value.serverId,
            reason: value.reason
        });
        
        res.json({
            success: true,
            message: 'Ban removed successfully'
        });
        
    } catch (error) {
        logger.error('Error removing ban', { error: error.message, stack: error.stack });
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/check', validateApiKey, async (req, res) => {
    try {
        const { error, value } = checkSchema.validate(req.body);
        if (error) {
            return res.status(400).json({ error: error.details[0].message });
        }
        
        const activeBans = Array.from(bans.values()).filter(ban => 
            ban.isActive && 
            ban.playerIdentifier === value.playerIdentifier &&
            (!ban.expireDate || new Date(ban.expireDate) > new Date())
        );
        
        if (activeBans.length > 0) {
            const ban = activeBans[0];
            res.json({
                banned: true,
                ban: {
                    id: ban.id,
                    reason: ban.reason,
                    banDate: ban.banDate,
                    expireDate: ban.expireDate,
                    adminName: ban.adminName
                }
            });
        } else {
            res.json({ banned: false });
        }
        
    } catch (error) {
        logger.error('Error checking ban', { error: error.message, stack: error.stack });
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/bulk-sync', validateApiKey, async (req, res) => {
    try {
        const serverId = req.body.serverId;
        if (!serverId) {
            return res.status(400).json({ error: 'Server ID required' });
        }
        
        servers.set(serverId, {
            lastSync: new Date(),
            ip: req.ip
        });
        
        const activeBans = Array.from(bans.values())
            .filter(ban => ban.isActive && (!ban.expireDate || new Date(ban.expireDate) > new Date()))
            .map(ban => ({
                id: ban.id,
                playerIdentifier: ban.playerIdentifier,
                reason: ban.reason,
                expires: ban.expireDate ? Math.floor(new Date(ban.expireDate).getTime() / 1000) : 0,
                banDate: Math.floor(new Date(ban.banDate).getTime() / 1000)
            }));
        
        res.json({
            success: true,
            bans: activeBans,
            timestamp: Math.floor(Date.now() / 1000)
        });
        
        logger.info('Bulk sync completed', { serverId, bansCount: activeBans.length });
        
    } catch (error) {
        logger.error('Error in bulk sync', { error: error.message, stack: error.stack });
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/stats', validateApiKey, (req, res) => {
    const now = new Date();
    const activeBans = Array.from(bans.values()).filter(ban => 
        ban.isActive && (!ban.expireDate || new Date(ban.expireDate) > now)
    );
    
    const recentBans = Array.from(bans.values()).filter(ban => 
        new Date(ban.banDate) > new Date(now.getTime() - 24 * 60 * 60 * 1000)
    );
    
    res.json({
        totalBans: bans.size,
        activeBans: activeBans.length,
        recentBans: recentBans.length,
        connectedServers: servers.size,
        uptime: process.uptime()
    });
});

app.use((err, req, res, next) => {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });
    res.status(500).json({ error: 'Internal server error' });
});

app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

const server = app.listen(PORT, () => {
    logger.info(`OnyxAC Central Service running on port ${PORT}`);
    console.log(`
    ╔═══════════════════════════════════════╗
    ║         OnyxAC Central Service        ║
    ║                                       ║
    ║  Port: ${PORT.toString().padEnd(30)} ║
    ║  Status: Running                      ║
    ║  Author: TheOGDev                     ║
    ╚═══════════════════════════════════════╝
    `);
});

process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    server.close(() => {
        logger.info('Process terminated');
        process.exit(0);
    });
});

process.on('uncaughtException', (error) => {
    logger.error('Uncaught exception', { error: error.message, stack: error.stack });
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled rejection', { reason, promise });
    process.exit(1);
});

module.exports = app;
