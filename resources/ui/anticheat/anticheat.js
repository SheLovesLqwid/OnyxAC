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

class AntiCheatPanel {
    constructor() {
        this.acData = null;
        this.detectionFilter = 'all';
        this.init();
    }

    init() {
        this.setupEventListeners();
    }

    setupEventListeners() {
        const refreshBtn = document.getElementById('refresh-bans');
        const banSearch = document.getElementById('ban-search');

        refreshBtn?.addEventListener('click', () => {
            this.refreshACData();
        });

        banSearch?.addEventListener('input', (e) => {
            this.filterBans(e.target.value);
        });

        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('unban-btn')) {
                const banId = e.target.dataset.banId;
                this.showUnbanDialog(banId);
            }

            if (e.target.classList.contains('filter-btn')) {
                this.setDetectionFilter(e.target.dataset.filter);
            }
        });

        document.addEventListener('change', (e) => {
            if (e.target.classList.contains('detector-toggle-input')) {
                const detectorName = e.target.dataset.detector;
                const enabled = e.target.checked;
                this.toggleDetector(detectorName, enabled);
            }

            if (e.target.classList.contains('detector-setting')) {
                const detectorName = e.target.dataset.detector;
                const setting = e.target.dataset.setting;
                const value = e.target.value;
                this.updateDetectorSetting(detectorName, setting, value);
            }
        });
    }

    updateACData(data) {
        this.acData = data;
        this.renderDetections();
        this.renderDetectorConfig();
        this.renderBanList();
        this.renderStats();
    }

    renderDetections() {
        const container = document.getElementById('detection-list');
        if (!container || !this.acData) return;

        const detections = this.acData.recentDetections || [];
        
        if (detections.length === 0) {
            container.innerHTML = '<div class="no-detections">No recent detections</div>';
            return;
        }

        const filterControls = `
            <div class="filter-controls">
                <button class="filter-btn ${this.detectionFilter === 'all' ? 'active' : ''}" data-filter="all">All</button>
                <button class="filter-btn ${this.detectionFilter === 'critical' ? 'active' : ''}" data-filter="critical">Critical</button>
                <button class="filter-btn ${this.detectionFilter === 'high' ? 'active' : ''}" data-filter="high">High</button>
                <button class="filter-btn ${this.detectionFilter === 'medium' ? 'active' : ''}" data-filter="medium">Medium</button>
                <button class="filter-btn ${this.detectionFilter === 'low' ? 'active' : ''}" data-filter="low">Low</button>
            </div>
        `;

        const filteredDetections = this.filterDetections(detections);
        const detectionsHtml = filteredDetections.map(detection => this.createDetectionCard(detection)).join('');

        container.innerHTML = filterControls + detectionsHtml;
    }

    filterDetections(detections) {
        if (this.detectionFilter === 'all') return detections;
        
        return detections.filter(detection => {
            const severity = this.getDetectionSeverity(detection.data?.scoreAdded || 0);
            return severity === this.detectionFilter;
        });
    }

    createDetectionCard(detection) {
        const severity = this.getDetectionSeverity(detection.data?.scoreAdded || 0);
        const timestamp = new Date(detection.timestamp * 1000).toLocaleString();
        
        return `
            <div class="detection-card ${severity}">
                <div class="detection-header">
                    <div class="detection-type">
                        <span class="detection-severity-indicator ${severity}"></span>
                        ${detection.data?.detectionType || 'Unknown'}
                    </div>
                    <div class="detection-timestamp">${timestamp}</div>
                </div>
                <div class="detection-player">Player: ${this.escapeHtml(detection.data?.playerName || 'Unknown')}</div>
                <div class="detection-details">
                    Score Added: +${detection.data?.scoreAdded || 0} (Total: ${detection.data?.totalScore || 0})
                    ${detection.data?.detectionData ? '<br>Data: ' + JSON.stringify(detection.data.detectionData, null, 2) : ''}
                </div>
            </div>
        `;
    }

    renderDetectorConfig() {
        const container = document.getElementById('detector-config');
        if (!container || !this.acData) return;

        const detectors = this.acData.detectors || {};
        
        container.innerHTML = Object.entries(detectors).map(([name, config]) => 
            this.createDetectorConfigItem(name, config)
        ).join('');
    }

    createDetectorConfigItem(name, config) {
        return `
            <div class="detector-config-item">
                <div class="detector-header">
                    <div class="detector-name">${this.formatDetectorName(name)}</div>
                    <label class="detector-toggle">
                        <input type="checkbox" class="detector-toggle-input" data-detector="${name}" ${config.enabled ? 'checked' : ''}>
                        <span class="toggle-slider"></span>
                    </label>
                </div>
                <div class="detector-settings">
                    <div class="setting-input">
                        <label>Score Weight</label>
                        <input type="number" class="detector-setting" data-detector="${name}" data-setting="scoreWeight" value="${config.scoreWeight || 0}" min="0" max="100">
                    </div>
                </div>
            </div>
        `;
    }

    renderBanList() {
        const container = document.getElementById('ban-list');
        if (!container) return;

        // This would be populated with actual ban data from the server
        container.innerHTML = '<div class="no-detections">Ban list would be displayed here</div>';
    }

    renderStats() {
        const container = document.getElementById('server-stats');
        if (!container || !this.acData) return;

        const stats = this.acData.serverStats || {};
        
        container.innerHTML = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-value">${stats.playersOnline || 0}</div>
                    <div class="stat-label">Players Online</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${stats.detectorsEnabled || 0}</div>
                    <div class="stat-label">Active Detectors</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${stats.totalDetections || 0}</div>
                    <div class="stat-label">Total Detections</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${stats.activeBans || 0}</div>
                    <div class="stat-label">Active Bans</div>
                </div>
            </div>
            <div class="chart-container">
                <div class="chart-title">Detection Activity (Last 24 Hours)</div>
                <div style="text-align: center; padding: 40px; color: rgba(255, 255, 255, 0.5);">
                    Chart would be displayed here
                </div>
            </div>
        `;
    }

    setDetectionFilter(filter) {
        this.detectionFilter = filter;
        this.renderDetections();
    }

    getDetectionSeverity(score) {
        if (score >= 40) return 'critical';
        if (score >= 25) return 'high';
        if (score >= 15) return 'medium';
        return 'low';
    }

    formatDetectorName(name) {
        return name.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase());
    }

    toggleDetector(detectorName, enabled) {
        fetch(`https://${GetParentResourceName()}/toggleDetector`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                detector: detectorName,
                enabled: enabled
            })
        });

        onyxUI.showNotification(`${this.formatDetectorName(detectorName)} ${enabled ? 'enabled' : 'disabled'}`, 'info');
    }

    updateDetectorSetting(detectorName, setting, value) {
        fetch(`https://${GetParentResourceName()}/updateDetectorSetting`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                detector: detectorName,
                setting: setting,
                value: value
            })
        });

        onyxUI.showNotification(`${this.formatDetectorName(detectorName)} ${setting} updated`, 'info');
    }

    showUnbanDialog(banId) {
        onyxUI.showModal(
            'Remove Ban',
            `Are you sure you want to remove ban ${banId}?`,
            [
                { id: 'reason', label: 'Reason for removal', type: 'text', placeholder: 'Enter reason...' }
            ],
            (values) => {
                this.executeBanAction('unban', banId, values.reason);
            }
        );
    }

    executeBanAction(action, banId, reason) {
        fetch(`https://${GetParentResourceName()}/banAction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                action: action,
                banId: banId,
                reason: reason
            })
        });

        onyxUI.showNotification(`Ban ${action} executed`, 'success');
    }

    refreshACData() {
        fetch(`https://${GetParentResourceName()}/refreshACData`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });

        onyxUI.showNotification('Anti-cheat data refreshed', 'info');
    }

    filterBans(searchTerm) {
        // Implementation for filtering bans
        console.log('Filtering bans with term:', searchTerm);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Override the updateACData method in the main UI class
onyxUI.updateACData = function(data) {
    if (window.antiCheatPanel) {
        window.antiCheatPanel.updateACData(data);
    }
};

// Initialize anti-cheat panel when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.antiCheatPanel = new AntiCheatPanel();
});
