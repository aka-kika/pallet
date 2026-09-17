import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
export const palettes = sqliteTable('palettes', {
  id: text('id').primaryKey(),
  data: text('data').notNull(),
  updatedAt: integer('updated_at').notNull(),
});
