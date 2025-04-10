let currentLobby = null;
let isLeader = false;

window.addEventListener('message', function(event) {
    const data = event.data;
    const mainMenu = document.getElementById('mainMenu');
    const createLobbyMenu = document.getElementById('createLobbyMenu');
    const lobbyMenu = document.getElementById('lobbyMenu');
    const lobbyList = document.getElementById('lobbyList');
    const weaponSelect = document.getElementById('weaponSelect');
    const lobbyInfo = document.getElementById('lobbyInfo');
    const startGameBtn = document.getElementById('startGameBtn');

    if (data.type === 'open') {
        mainMenu.style.display = 'block';
        createLobbyMenu.style.display = 'none';
        lobbyMenu.style.display = 'none';
    } else if (data.type === 'close') {
        mainMenu.style.display = 'none';
        createLobbyMenu.style.display = 'none';
        lobbyMenu.style.display = 'none';
    } else if (data.type === 'updateLobbies') {
        weaponSelect.innerHTML = '';
        data.weaponList.forEach(weapon => {
            const option = document.createElement('option');
            option.value = weapon.hash;
            option.textContent = weapon.name;
            weaponSelect.appendChild(option);
        });

        lobbyList.innerHTML = '';
        if (data.lobbies.length > 0) {
            data.lobbies.forEach(lobby => {
                const lobbyItem = document.createElement('div');
                lobbyItem.className = 'lobby-item';
                lobbyItem.innerHTML = `
                    <div><strong>${lobby.weaponName}</strong></div>
                    <div>Длительность: ${lobby.duration} мин</div>
                    <div>Игроки: ${lobby.players.length}/10</div> <!-- Изменено с 2 на 10 -->
                `;
                lobbyItem.addEventListener('click', () => {
                    fetch(`https://${GetParentResourceName()}/joinLobby`, {
                        method: 'POST',
                        headers: {'Content-Type': 'application/json'},
                        body: JSON.stringify({ lobbyId: lobby.id })
                    });
                });
                lobbyList.appendChild(lobbyItem);
            });
        } else {
            lobbyList.innerHTML = '<div>Нет доступных лобби</div>';
        }
    } else if (data.type === 'joinedLobby') {
        currentLobby = data.lobby;
        isLeader = data.isLeader;
        mainMenu.style.display = 'none';
        createLobbyMenu.style.display = 'none';
        lobbyMenu.style.display = 'block';
        lobbyInfo.innerHTML = `
            <div><strong>Оружие:</strong> ${currentLobby.weaponName}</div>
            <div><strong>Длительность:</strong> ${currentLobby.duration} мин</div>
            <div><strong>Игроки (${currentLobby.players.length}/10):</strong></div> <!-- Изменено с 2 на 10 -->
            <div class="player-list">
                ${currentLobby.playersNames.map(name => `<div class="player-item">${name || 'Неизвестный'}</div>`).join('')}
            </div>
        `;
        startGameBtn.style.display = isLeader ? 'block' : 'none';
    }
});

document.getElementById('createLobbyBtn').addEventListener('click', () => {
    document.getElementById('mainMenu').style.display = 'none';
    document.getElementById('createLobbyMenu').style.display = 'block';
});

document.getElementById('backToMain').addEventListener('click', () => {
    document.getElementById('createLobbyMenu').style.display = 'none';
    document.getElementById('mainMenu').style.display = 'block';
});

document.getElementById('confirmCreateLobby').addEventListener('click', () => {
    const weapon = document.getElementById('weaponSelect').value;
    const duration = document.getElementById('durationSelect').value;
    fetch(`https://${GetParentResourceName()}/createLobby`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ weapon, duration })
    });
});

document.getElementById('leaveLobbyBtn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'}
    });
    currentLobby = null;
    isLeader = false;
});

document.getElementById('startGameBtn').addEventListener('click', () => {
    if (currentLobby && currentLobby.players.length >= 2) {
        fetch(`https://${GetParentResourceName()}/startGame`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ lobbyId: currentLobby.id })
        });
    } else {
        alert('Нужно минимум 2 игрока!');
    }
});

document.getElementById('closeMain').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'}
    });
});

document.getElementById('closeCreate').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'}
    });
});

document.getElementById('closeLobby').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'}
    });
    currentLobby = null;
    isLeader = false;
});