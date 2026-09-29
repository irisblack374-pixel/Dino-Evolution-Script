import {
  ChatInputCommandInteraction,
  Client,
  REST,
  Routes,
  SlashCommandBuilder
} from "discord.js";
import { questStore } from "../services/questStore.js";

const commands = [
  new SlashCommandBuilder().setName("quests").setDescription("Show available quests"),
  new SlashCommandBuilder().setName("quest-progress").setDescription("Show your quest progress"),
  new SlashCommandBuilder()
    .setName("quest-complete")
    .setDescription("Claim a completed quest")
    .addStringOption((option) =>
      option.setName("quest")
        .setDescription("Quest ID")
        .setRequired(true)
        .addChoices(
          { name: "messages", value: "messages" },
          { name: "voice", value: "voice" }
        )
    )
].map((command) => command.toJSON());

export function registerCommands(client: Client): void {
  client.once("ready", async (readyClient) => {
    const rest = new REST({ version: "10" }).setToken(process.env.DISCORD_TOKEN!);
    await rest.put(Routes.applicationCommands(readyClient.user.id), { body: commands });
  });

  client.on("interactionCreate", async (interaction) => {
    if (!interaction.isChatInputCommand() || !interaction.guild) return;
    await handleCommand(interaction);
  });
}

async function handleCommand(interaction: ChatInputCommandInteraction): Promise<void> {
  const progress = questStore.get(interaction.guild!.id, interaction.user.id);

  if (interaction.commandName === "quests") {
    await interaction.reply("messages — Send 10 messages (100 points)\nvoice — Stay in voice for 10 minutes (150 points)");
    return;
  }

  if (interaction.commandName === "quest-progress") {
    await interaction.reply(`Messages: ${Math.min(progress.messages, 10)}/10\nVoice: ${Math.min(progress.voiceMinutes, 10)}/10 minutes`);
    return;
  }

  if (interaction.commandName === "quest-complete") {
    const quest = interaction.options.getString("quest", true) as "messages" | "voice";
    if (progress.claimed.has(quest)) {
      await interaction.reply("You already claimed this quest.");
      return;
    }

    const complete = quest === "messages" ? progress.messages >= 10 : progress.voiceMinutes >= 10;
    if (!complete) {
      await interaction.reply("This quest is not completed yet.");
      return;
    }

    progress.claimed.add(quest);
    await interaction.reply(`Quest completed. Reward: ${quest === "messages" ? 100 : 150} points.`);
  }
}
