# Roblox Discord Bridge

Bridge dua arah antara Roblox game dan Discord server. Player di Roblox bisa mengirim pesan ke Discord dan sebaliknya, player di Discord bisa mengirim pesan ke dalam game Roblox.

## 🎯 Fitur

- ✅ **Roblox → Discord**: Player di game Roblox bisa mengirim pesan ke channel Discord
- ✅ **Discord → Roblox**: Pesan dari Discord muncul di UI mini Discord di dalam game
- ✅ **Real-time**: Polling system untuk sinkronisasi pesan
- ✅ **UI Modern**: Interface mirip Discord di dalam Roblox

## 📋 Prerequisites

1. **Node.js** (v16 atau lebih baru)
2. **Discord Bot Token** - Buat bot di [Discord Developer Portal](https://discord.com/developers/applications)
3. **Roblox Studio** - Untuk menjalankan script client

## 🚀 Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Setup Discord Bot

1. Pergi ke [Discord Developer Portal](https://discord.com/developers/applications)
2. Buat aplikasi baru atau pilih yang sudah ada
3. Pergi ke tab "Bot" dan buat bot
4. Copy **Bot Token**
5. Enable **Message Content Intent** di tab "Bot" (penting!)
6. Invite bot ke server dengan permission:
   - Send Messages
   - Read Message History
   - View Channels

### 3. Konfigurasi Environment

1. Copy `.env.example` menjadi `.env`:
   ```bash
   copy .env.example .env
   ```

2. Edit `.env` dan isi dengan:
   ```
   DISCORD_TOKEN=your_discord_bot_token_here
   CHANNEL_ID=your_discord_channel_id_here
   PORT=3000
   SHARED_SECRET=your_secure_secret_key_here
   ```

   **Cara mendapatkan CHANNEL_ID:**
   - Enable Developer Mode di Discord (Settings > Advanced > Developer Mode)
   - Right-click pada channel yang ingin digunakan
   - Pilih "Copy ID"

### 4. Jalankan Server

```bash
npm start
```

Server akan berjalan di `http://localhost:3000`

### 5. Setup Roblox Client

1. Buka Roblox Studio
2. Buka game yang ingin ditambahkan fitur Discord Bridge
3. Buka file `roblox-client.lua` di project ini
4. **Edit konfigurasi di bagian atas script:**
   ```lua
   local API_URL = "http://localhost:3000"  -- Ganti dengan URL/IP server kamu
   local SHARED_SECRET = "dev-secret"  -- Harus sama dengan di .env
   ```
5. Copy seluruh isi `roblox-client.lua`
6. Di Roblox Studio, buat **LocalScript** baru di:
   - `StarterPlayer > StarterPlayerScripts` (untuk LocalScript)
   - Atau `ServerScriptService` (untuk ServerScript)
7. Paste script ke dalam LocalScript/ServerScript
8. **PENTING**: Di Roblox Studio, enable HTTP requests:
   - File > Game Settings > Security
   - Enable "Allow HTTP Requests"
   - Tambahkan domain server kamu ke whitelist

## 🌐 Deploy ke Production

Jika ingin deploy server agar bisa diakses dari luar:

### Option 1: Local Network (LAN)
- Ganti `API_URL` di Roblox script dengan IP lokal kamu (misal: `http://192.168.1.100:3000`)
- Pastikan firewall mengizinkan port 3000

### Option 2: Cloud Hosting
- Deploy ke platform seperti:
  - **Railway** (railway.app)
  - **Render** (render.com)
  - **Heroku** (heroku.com)
  - **VPS** (DigitalOcean, AWS, dll)
- Update `API_URL` di Roblox script dengan URL hosting kamu
- Pastikan menggunakan HTTPS jika memungkinkan

### Option 3: ngrok (Development/Testing)
```bash
ngrok http 3000
```
Copy URL yang diberikan dan gunakan sebagai `API_URL` di Roblox script.

## 📁 Struktur Project

```
rbx-discord-bridge/
├── index.js              # Server utama (Express + Discord.js)
├── roblox-client.lua     # Script untuk Roblox Studio
├── package.json
├── .env                  # Konfigurasi (jangan commit!)
├── .env.example          # Template konfigurasi
└── README.md
```

## 🔧 API Endpoints

### `POST /roblox/send`
Mengirim pesan dari Roblox ke Discord.

**Headers:**
```
x-shared-secret: your_secret_key
```

**Body:**
```json
{
  "name": "PlayerName",
  "text": "Pesan dari Roblox"
}
```

### `GET /roblox/poll`
Mendapatkan pesan baru dari Discord (polling).

**Headers:**
```
x-shared-secret: your_secret_key
```

**Query:**
```
?since=123  // ID pesan terakhir yang sudah diterima
```

**Response:**
```json
{
  "ok": true,
  "messages": [
    {
      "id": 1,
      "source": "discord",
      "name": "Username",
      "text": "Pesan dari Discord",
      "ts": 1234567890
    }
  ],
  "nextSince": 1
}
```

## ⚠️ Troubleshooting

### Bot tidak menerima pesan
- Pastikan **Message Content Intent** sudah di-enable di Discord Developer Portal
- Pastikan bot sudah di-invite ke server dengan permission yang benar
- Pastikan `CHANNEL_ID` sudah benar

### Roblox tidak bisa connect ke server
- Pastikan HTTP Requests sudah di-enable di Roblox Studio
- Pastikan `API_URL` sudah benar
- Pastikan server sudah running
- Cek firewall/network settings

### Pesan tidak muncul di Roblox
- Pastikan `SHARED_SECRET` sama antara server dan client
- Cek console server untuk error
- Pastikan polling interval tidak terlalu cepat (minimal 1 detik)

## 🔒 Security Notes

- **JANGAN** commit file `.env` ke git
- Gunakan `SHARED_SECRET` yang kuat di production
- Pertimbangkan rate limiting untuk mencegah spam
- Gunakan HTTPS di production jika memungkinkan

## 📝 License

ISC

## 🤝 Contributing

Feel free to submit issues atau pull requests!
