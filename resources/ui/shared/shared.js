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

class OnyxUI {
    constructor() {
        this.currentMenu = null;
        this.notifications = [];
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.setupTabSystem();
        this.setupModal();
    }

    setupEventListeners() {
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeAllMenus();
            }
        });

        window.addEventListener('message', (event) => {
            this.handleMessage(event.data);
        });
    }

    setupTabSystem() {
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('tab-btn')) {
                const tabName = e.target.dataset.tab;
                const container = e.target.closest('.menu-container');
                this.switchTab(container, tabName);
            }
        });
    }

    setupModal() {
        const modal = document.getElementById('modal');
        const closeBtn = document.getElementById('modal-close');
        const cancelBtn = document.getElementById('modal-cancel');

        [closeBtn, cancelBtn].forEach(btn => {
            btn?.addEventListener('click', () => {
                this.closeModal();
            });
        });

        modal?.addEventListener('click', (e) => {
            if (e.target === modal) {
                this.closeModal();
            }
        });
    }

    handleMessage(data) {
        switch (data.type) {
            case 'openAdminMenu':
                this.openAdminMenu();
                break;
            case 'openACMenu':
                this.openACMenu();
                break;
            case 'showNotification':
                this.showNotification(data.message, data.notificationType);
                break;
            case 'showAnnouncement':
                this.showAnnouncement(data.message);
                break;
            case 'updatePlayerList':
                this.updatePlayerList(data.players);
                break;
            case 'updateACData':
                this.updateACData(data.data);
                break;
        }
    }

    openAdminMenu() {
        this.closeAllMenus();
        const menu = document.getElementById('admin-menu');
        menu.style.display = 'block';
        this.currentMenu = 'admin';
        
        document.getElementById('close-admin').addEventListener('click', () => {
            this.closeAdminMenu();
        });
    }

    openACMenu() {
        this.closeAllMenus();
        const menu = document.getElementById('ac-menu');
        menu.style.display = 'block';
        this.currentMenu = 'ac';
        
        document.getElementById('close-ac').addEventListener('click', () => {
            this.closeACMenu();
        });
    }

    closeAdminMenu() {
        document.getElementById('admin-menu').style.display = 'none';
        this.currentMenu = null;
        fetch(`https://${GetParentResourceName()}/closeAdminMenu`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }

    closeACMenu() {
        document.getElementById('ac-menu').style.display = 'none';
        this.currentMenu = null;
        fetch(`https://${GetParentResourceName()}/closeACMenu`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }

    closeAllMenus() {
        if (this.currentMenu === 'admin') {
            this.closeAdminMenu();
        } else if (this.currentMenu === 'ac') {
            this.closeACMenu();
        }
    }

    switchTab(container, tabName) {
        const tabBtns = container.querySelectorAll('.tab-btn');
        const tabContents = container.querySelectorAll('.tab-content');

        tabBtns.forEach(btn => btn.classList.remove('active'));
        tabContents.forEach(content => content.classList.remove('active'));

        const activeBtn = container.querySelector(`[data-tab="${tabName}"]`);
        const activeContent = container.querySelector(`#${tabName}-tab`);

        if (activeBtn && activeContent) {
            activeBtn.classList.add('active');
            activeContent.classList.add('active');
        }
    }

    showNotification(message, type = 'info') {
        const container = document.getElementById('notification-container');
        const notification = document.createElement('div');
        
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        container.appendChild(notification);
        
        setTimeout(() => {
            notification.style.animation = 'slideOutRight 0.3s ease-in forwards';
            setTimeout(() => {
                container.removeChild(notification);
            }, 300);
        }, 5000);
    }

    showAnnouncement(message) {
        const container = document.getElementById('announcement-container');
        const announcement = document.createElement('div');
        
        announcement.className = 'announcement';
        announcement.textContent = message;
        
        container.appendChild(announcement);
        
        setTimeout(() => {
            announcement.style.animation = 'fadeOut 0.5s ease-in forwards';
            setTimeout(() => {
                if (container.contains(announcement)) {
                    container.removeChild(announcement);
                }
            }, 500);
        }, 8000);
    }

    showModal(title, message, inputs = [], callback = null) {
        const modal = document.getElementById('modal');
        const titleEl = document.getElementById('modal-title');
        const messageEl = document.getElementById('modal-message');
        const inputsEl = document.getElementById('modal-inputs');
        const confirmBtn = document.getElementById('modal-confirm');

        titleEl.textContent = title;
        messageEl.textContent = message;
        
        inputsEl.innerHTML = '';
        inputs.forEach(input => {
            const inputGroup = document.createElement('div');
            inputGroup.className = 'input-group';
            
            if (input.label) {
                const label = document.createElement('label');
                label.textContent = input.label;
                inputGroup.appendChild(label);
            }
            
            let inputEl;
            if (input.type === 'textarea') {
                inputEl = document.createElement('textarea');
            } else if (input.type === 'select') {
                inputEl = document.createElement('select');
                input.options?.forEach(option => {
                    const optionEl = document.createElement('option');
                    optionEl.value = option.value;
                    optionEl.textContent = option.text;
                    inputEl.appendChild(optionEl);
                });
            } else {
                inputEl = document.createElement('input');
                inputEl.type = input.type || 'text';
            }
            
            inputEl.id = input.id;
            inputEl.placeholder = input.placeholder || '';
            inputEl.value = input.value || '';
            
            inputGroup.appendChild(inputEl);
            inputsEl.appendChild(inputGroup);
        });

        confirmBtn.onclick = () => {
            const values = {};
            inputs.forEach(input => {
                const el = document.getElementById(input.id);
                values[input.id] = el.value;
            });
            
            if (callback) {
                callback(values);
            }
            
            this.closeModal();
        };

        modal.style.display = 'flex';
    }

    closeModal() {
        document.getElementById('modal').style.display = 'none';
    }

    updatePlayerList(players) {
        // Implemented in admin.js
    }

    updateACData(data) {
        // Implemented in anticheat.js
    }
}

function GetParentResourceName() {
    return window.location.hostname;
}

const onyxUI = new OnyxUI();
