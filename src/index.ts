import "dotenv/config";
import { createClient } from "./providers/client.js";
import { registerEvents } from "./handler/registerEvents.js";
import { registerCommands } from "./handler/registerCommands.js";
import { logger } from "./utils/logger.js";

const token = process.env.DISCORD_TOKEN;
if (!token) throw new Error("DISCORD_TOKEN is missing. Add it to .env");

const client = createClient();
registerEvents(client);
registerCommands(client);

client.login(token).catch((error) => {
  logger.error("Failed to log in to Discord", error);
  process.exitCode = 1;
});
