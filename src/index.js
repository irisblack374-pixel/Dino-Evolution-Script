import "dotenv/config";
import {
  Client,
  GatewayIntentBits,
  REST,
  Routes,
  SlashCommandBuilder
} from "discord.js";

const token = process.env.DISCORD_TOKEN;
if (!token) throw new Error("DISCORD_TOKEN is missing.");

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.GuildVoiceStates
  ]
});

const progress = new Map();

const quests = [
  { id: "messages", name: "Send 10 messages", target: 10, reward: 100 },
  { id: "voice", name: "Stay in voice for 10 minutes", target: 10, reward: 150 }
];

function key(guildId, userId) {
  return `${guildId}:${userId}`;
}

function getProgress(guildId, userId) {
  const k = key(guildId, userId);
  if (!progress.has(k)) {
    progress.set(k, { messages: 0, voiceMinutes: 0, claimed: new Set() });
  }
  return progress.get(k);
}

const commands = [
  new SlashCommandBuilder()
    .setName("quests")
    .setDescription("Show available quests"),
  new SlashCommandBuilder()
    .setName("quest-progress")
    .setDescription("Show your quest progress"),
  new SlashCommandBuilder()
    .setName("quest-complete")
    .setDescription("Claim a completed quest")
    .addStringOption(o =>
      o.setName("quest")
        .setDescription("Quest ID: messages or voice")
        .setRequired(true)
        .addChoices(
          { name: "messages", value: "messages" },
          { name: "voice", value: "voice" }
        )
    )
].map(c => c.toJSON());

client.once("ready", async () => {
  const rest = new REST({ version: "10" }).setToken(token);
  await rest.put(Routes.applicationCommands(client.user.id), { body: commands });
  console.log(`Logged in as ${client.user.tag}`);
});

client.on("messageCreate", message => {
  if (message.author.bot || !message.guild) return;
  getProgress(message.guild.id, message.author.id).messages++;
});

client.on("voiceStateUpdate", (oldState, newState) => {
  if (oldState.member?.user.bot) return;
  if (!oldState.channelId && newState.channelId) {
    newState.member._questVoiceStartedAt = Date.now();
  }
  if (oldState.channelId && !newState.channelId) {
    const started = oldState.member._questVoiceStartedAt;
    if (!started) return;
    const minutes = Math.floor((Date.now() - started) / 60000);
    getProgress(oldState.guild.id, oldState.member.id).voiceMinutes += minutes;
    delete oldState.member._questVoiceStartedAt;
  }
});

client.on("interactionCreate", async interaction => {
  if (!interaction.isChatInputCommand() || !interaction.guild) return;

  const p = getProgress(interaction.guild.id, interaction.user.id);

  if (interaction.commandName === "quests") {
    return interaction.reply(
      "Available quests:\n" +
      "• messages — Send 10 messages (100 points)\n" +
      "• voice — Stay in voice for 10 minutes (150 points)"
    );
  }

  if (interaction.commandName === "quest-progress") {
    return interaction.reply(
      `Messages: ${Math.min(p.messages, 10)}/10\nVoice: ${Math.min(p.voiceMinutes, 10)}/10 minutes`
    );
  }

  if (interaction.commandName === "quest-complete") {
    const id = interaction.options.getString("quest", true);

    if (p.claimed.has(id)) {
      return interaction.reply("You already claimed this quest.");
    }

    const complete =
      id === "messages" ? p.messages >= 10 :
      id === "voice" ? p.voiceMinutes >= 10 :
      false;

    if (!complete) return interaction.reply("This quest is not completed yet.");

    p.claimed.add(id);
    const reward = id === "messages" ? 100 : 150;
    return interaction.reply(`Quest completed. Reward: ${reward} points.`);
  }
});

client.login(token);
