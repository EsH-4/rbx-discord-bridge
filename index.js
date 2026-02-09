import express from "express";
import { Client, GatewayIntentBits, Partials } from "discord.js";
import "dotenv/config";

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const DISCORD_TOKEN = process.env.DISCORD_TOKEN;
const CHANNEL_ID = process.env.CHANNEL_ID;
const SHARED_SECRET = process.env.SHARED_SECRET || "dev-secret";

// buffer in-memory (MVP)
let nextId = 1;
const buffer = []; // { id, source, name, text, ts }
const MAX_BUFFER = 50;

function pushMessage(msg) {
  buffer.push(msg);
  while (buffer.length > MAX_BUFFER) buffer.shift();
}

function auth(req, res) {
  const secret = req.header("x-shared-secret");
  if (!secret || secret !== SHARED_SECRET) {
    res.status(401).json({ error: "unauthorized" });
    return false;
  }
  return true;
}

// Discord bot
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent, // perlu kalau mau baca konten pesan
  ],
  partials: [Partials.Channel],
});

client.on("ready", () => {
  console.log(`Bot ready as ${client.user.tag}`);
});

client.on("messageCreate", async (message) => {
  try {
    if (message.author.bot) return;
    if (message.channelId !== CHANNEL_ID) return;

    // simpan ke buffer untuk dipoll Roblox
    pushMessage({
      id: nextId++,
      source: "discord",
      name: message.member?.displayName || message.author.username,
      text: message.content?.slice(0, 200) || "",
      ts: Date.now(),
    });
  } catch (e) {
    console.error("messageCreate error", e);
  }
});

// Roblox -> Discord
app.post("/roblox/send", async (req, res) => {
  if (!auth(req, res)) return;

  const { name, text } = req.body || {};
  const safeName = String(name || "Roblox").slice(0, 32);
  const safeText = String(text || "").slice(0, 200);

  if (!safeText.trim()) return res.json({ ok: true, skipped: true });

  try {
    const channel = await client.channels.fetch(CHANNEL_ID);
    await channel.send(`**[RBX] ${safeName}:** ${safeText}`);

    // optional: juga masuk buffer supaya Roblox client lain lihat echo yang sama formatnya
    pushMessage({
      id: nextId++,
      source: "roblox",
      name: safeName,
      text: safeText,
      ts: Date.now(),
    });

    res.json({ ok: true });
  } catch (e) {
    console.error("send error", e);
    res.status(500).json({ ok: false });
  }
});

// Discord -> Roblox (polling)
app.get("/roblox/poll", (req, res) => {
  if (!auth(req, res)) return;

  const since = Number(req.query.since || 0);
  const messages = buffer.filter((m) => m.id > since);
  const nextSince = messages.length ? messages[messages.length - 1].id : since;

  res.json({ ok: true, messages, nextSince });
});

app.get("/", (_, res) => res.send("ok"));

app.listen(PORT, () => console.log(`API listening on :${PORT}`));
client.login(DISCORD_TOKEN);
