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

class AdminPanel {
    constructor() {
        this.players = [];
        this.filteredPlayers = [];
        this.searchTerm = '';
        this.init();
    }

    init() {
        this.setupEventListeners();
    }

    setupEventListeners() {
        const searchInput = document.getElementById('player-search');
        const refreshBtn = document.getElementById('refresh-players');

        searchInput?.addEventListener('input', (e) => {
            this.searchTerm = e.target.value.toLowerCase();
            this.filterPlayers();
            this.renderPlayerList();
        });

        refreshBtn?.addEventListener('click', () => {
            this.refreshPlayerList();
        });

        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('action-btn-small')) {
                const action = e.target.dataset.action;
                const playerId = parseInt(e.target.dataset.playerId);
                this.handlePlayerAction(action, playerId);
            }

            if (e.target.classList.contains('action-btn')) {
                const action = e.target.dataset.action;
                this.handleQuickAction(action);
            }
        });
    }

    updatePlayerList(players) {
        this.players = players || [];
        this.filterPlayers();
        this.renderPlayerList();
    }

    filterPlayers() {
        if (!this.searchTerm) {
            this.filteredPlayers = [...this.players];
        } else {
            this.filteredPlayers = this.players.filter(player => 
                player.name.toLowerCase().includes(this.searchTerm) ||
                player.id.toString().includes(this.searchTerm)
            );
        }
    }

    renderPlayerList() {
        const container = document.getElementById('player-list');
        if (!container) return;

        if (this.filteredPlayers.length === 0) {
            container.innerHTML = '<div class="no-players">No players found</div>';
            return;
        }

        container.innerHTML = this.filteredPlayers.map(player => this.createPlayerCard(player)).join('');
    }

    createPlayerCard(player) {
        const scoreClass = this.getScoreClass(player.score);
        
        return `
            <div class="player-card">
                <div class="player-header">
                    <div class="player-info">
                        <div class="player-name">${this.escapeHtml(player.name)}</div>
                        <div class="player-details">
                            <span class="player-id">ID: ${player.id}</span>
                            <span class="player-ping">Ping: ${player.ping}ms</span>
                            <span class="player-score ${scoreClass}">Score: ${player.score}</span>
                        </div>
                    </div>
                    <div class="player-actions">
                        <button class="action-btn-small kick" data-action="kick" data-player-id="${player.id}">Kick</button>
                        <button class="action-btn-small ban" data-action="ban" data-player-id="${player.id}">Ban</button>
                        <button class="action-btn-small warn" data-action="warn" data-player-id="${player.id}">Warn</button>
                        <button class="action-btn-small tp" data-action="tp" data-player-id="${player.id}">TP</button>
                        <button class="action-btn-small bring" data-action="bring" data-player-id="${player.id}">Bring</button>
                        <button class="action-btn-small freeze" data-action="freeze" data-player-id="${player.id}">Freeze</button>
                        <button class="action-btn-small spectate" data-action="spectate" data-player-id="${player.id}">Spectate</button>
                    </div>
                </div>
                ${this.createIdentifiersList(player.identifiers)}
            </div>
        `;
    }

    createIdentifiersList(identifiers) {
        if (!identifiers || identifiers.length === 0) return '';
        
        const identifierElements = identifiers.map(id => {
            const [type, value] = id.split(':');
            return `<span class="identifier">${type}: ${value.substring(0, 8)}...</span>`;
        }).join('');

        return `<div class="player-identifiers">${identifierElements}</div>`;
    }

    getScoreClass(score) {
        if (score >= 150) return 'critical';
        if (score >= 75) return 'high';
        if (score >= 25) return 'medium';
        return 'low';
    }

    handlePlayerAction(action, playerId) {
        const player = this.players.find(p => p.id === playerId);
        if (!player) return;

        switch (action) {
            case 'kick':
                this.showKickDialog(playerId, player.name);
                break;
            case 'ban':
                this.showBanDialog(playerId, player.name);
                break;
            case 'warn':
                this.showWarnDialog(playerId, player.name);
                break;
            case 'tp':
            case 'bring':
            case 'freeze':
            case 'spectate':
                this.executeAction(action, playerId);
                break;
        }
    }

    showKickDialog(playerId, playerName) {
        onyxUI.showModal(
            'Kick Player',
            `Are you sure you want to kick ${playerName}?`,
            [
                { id: 'reason', label: 'Reason', type: 'text', placeholder: 'Enter kick reason...' }
            ],
            (values) => {
                this.executeAction('kick', playerId, { reason: values.reason });
            }
        );
    }

    showBanDialog(playerId, playerName) {
        onyxUI.showModal(
            'Ban Player',
            `Are you sure you want to ban ${playerName}?`,
            [
                { id: 'duration', label: 'Duration (minutes, 0 = permanent)', type: 'number', value: '1440' },
                { id: 'reason', label: 'Reason', type: 'textarea', placeholder: 'Enter ban reason...' }
            ],
            (values) => {
                this.executeAction('ban', playerId, { 
                    duration: parseInt(values.duration) || 0,
                    reason: values.reason 
                });
            }
        );
    }

    showWarnDialog(playerId, playerName) {
        onyxUI.showModal(
            'Warn Player',
            `Send a warning to ${playerName}`,
            [
                { id: 'reason', label: 'Warning Message', type: 'textarea', placeholder: 'Enter warning message...' }
            ],
            (values) => {
                this.executeAction('warn', playerId, { reason: values.reason });
            }
        );
    }

    executeAction(action, targetId, data = {}) {
        fetch(`https://${GetParentResourceName()}/adminAction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                action: action,
                targetId: targetId,
                ...data
            })
        });

        onyxUI.showNotification(`Action ${action} executed for player ${targetId}`, 'success');
    }

    handleQuickAction(action) {
        switch (action) {
            case 'announce':
                this.showAnnounceDialog();
                break;
            case 'restart-warning':
                this.showRestartWarning();
                break;
            case 'clear-area':
                this.clearArea();
                break;
            case 'weather':
                this.showWeatherDialog();
                break;
        }
    }

    showAnnounceDialog() {
        onyxUI.showModal(
            'Server Announcement',
            'Send a message to all players',
            [
                { id: 'message', label: 'Announcement', type: 'textarea', placeholder: 'Enter announcement message...' }
            ],
            (values) => {
                this.executeAction('announce', null, { message: values.message });
            }
        );
    }

    showRestartWarning() {
        onyxUI.showModal(
            'Restart Warning',
            'Send a server restart warning',
            [
                { 
                    id: 'time', 
                    label: 'Time until restart', 
                    type: 'select',
                    options: [
                        { value: '5', text: '5 minutes' },
                        { value: '10', text: '10 minutes' },
                        { value: '15', text: '15 minutes' },
                        { value: '30', text: '30 minutes' }
                    ]
                }
            ],
            (values) => {
                const message = `Server restart in ${values.time} minutes. Please finish your activities.`;
                this.executeAction('announce', null, { message: message });
            }
        );
    }

    clearArea() {
        onyxUI.showNotification('Area clearing functionality would be implemented here', 'info');
    }

    showWeatherDialog() {
        onyxUI.showModal(
            'Change Weather',
            'Select new weather condition',
            [
                { 
                    id: 'weather', 
                    label: 'Weather Type', 
                    type: 'select',
                    options: [
                        { value: 'CLEAR', text: 'Clear' },
                        { value: 'CLOUDS', text: 'Cloudy' },
                        { value: 'RAIN', text: 'Rain' },
                        { value: 'THUNDER', text: 'Thunder' },
                        { value: 'FOG', text: 'Fog' }
                    ]
                }
            ],
            (values) => {
                this.executeAction('weather', null, { weather: values.weather });
            }
        );
    }

    refreshPlayerList() {
        fetch(`https://${GetParentResourceName()}/refreshPlayerList`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });

        onyxUI.showNotification('Player list refreshed', 'info');
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Override the updatePlayerList method in the main UI class
onyxUI.updatePlayerList = function(players) {
    if (window.adminPanel) {
        window.adminPanel.updatePlayerList(players);
    }
};

// Initialize admin panel when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.adminPanel = new AdminPanel();
});
