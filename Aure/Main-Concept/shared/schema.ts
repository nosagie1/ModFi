import { pgTable, text, serial, integer, decimal, timestamp } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  username: text("username").unique().notNull(),
  email: text("email").unique(),
  password: text("password").notNull(),
  greeting: text("greeting").notNull(),
  welcomeMessage: text("welcome_message").notNull(),
});

export const accounts = pgTable("accounts", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull(),
  balance: decimal("balance", { precision: 10, scale: 2 }).notNull(),
  accountNumber: text("account_number"),
  routingNumber: text("routing_number"),
});

export const cards = pgTable("cards", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull(),
  holderName: text("holder_name").notNull(),
  lastFourDigits: text("last_four_digits").notNull(),
  expiry: text("expiry").notNull(),
  type: text("type").notNull(),
  balance: decimal("balance", { precision: 10, scale: 2 }).notNull().default("0.00"),
});

export const transactions = pgTable("transactions", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull(),
  merchant: text("merchant").notNull(),
  amount: decimal("amount", { precision: 10, scale: 2 }).notNull(),
  paymentMethod: text("payment_method").notNull(),
  date: timestamp("date").notNull(),
  icon: text("icon").notNull(),
  iconColor: text("icon_color").notNull(),
});

export const agencies = pgTable("agencies", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  name: text("name").notNull(),
  commissionRate: decimal("commission_rate", { precision: 5, scale: 4 }).notNull(), // Store as decimal (e.g., 0.2 for 20%)
  currency: text("currency").notNull().default("USD"), // ISO 3-letter code
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const jobs = pgTable("jobs", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  agencyId: integer("agency_id").references(() => agencies.id), // Link to agencies table
  client: text("client").notNull(),
  jobTitle: text("job_title"),
  bookedBy: text("booked_by").notNull(), // Agency name (kept for backward compatibility)
  status: text("status").notNull(), // "Pending", "Invoiced", "Partially Paid", "Received"
  jobDate: timestamp("job_date").notNull(),
  dueDate: timestamp("due_date").notNull(),
  amount: decimal("amount", { precision: 10, scale: 2 }).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// Relations
export const usersRelations = relations(users, ({ one, many }) => ({
  account: one(accounts, {
    fields: [users.id],
    references: [accounts.userId],
  }),
  card: one(cards, {
    fields: [users.id],
    references: [cards.userId],
  }),
  transactions: many(transactions),
  jobs: many(jobs),
  agencies: many(agencies),
}));

export const accountsRelations = relations(accounts, ({ one }) => ({
  user: one(users, {
    fields: [accounts.userId],
    references: [users.id],
  }),
}));

export const cardsRelations = relations(cards, ({ one }) => ({
  user: one(users, {
    fields: [cards.userId],
    references: [users.id],
  }),
}));

export const transactionsRelations = relations(transactions, ({ one }) => ({
  user: one(users, {
    fields: [transactions.userId],
    references: [users.id],
  }),
}));

export const agenciesRelations = relations(agencies, ({ one, many }) => ({
  user: one(users, {
    fields: [agencies.userId],
    references: [users.id],
  }),
  jobs: many(jobs),
}));

export const jobsRelations = relations(jobs, ({ one }) => ({
  user: one(users, {
    fields: [jobs.userId],
    references: [users.id],
  }),
  agency: one(agencies, {
    fields: [jobs.agencyId],
    references: [agencies.id],
  }),
}));

export const insertUserSchema = createInsertSchema(users).omit({ id: true });
export const insertAccountSchema = createInsertSchema(accounts).omit({ id: true });
export const insertCardSchema = createInsertSchema(cards).omit({ id: true });
export const insertTransactionSchema = createInsertSchema(transactions).omit({ id: true });
export const insertAgencySchema = createInsertSchema(agencies).omit({ id: true, createdAt: true });
export const insertJobSchema = createInsertSchema(jobs).omit({ id: true, createdAt: true });

export type User = typeof users.$inferSelect;
export type Account = typeof accounts.$inferSelect;
export type Card = typeof cards.$inferSelect;
export type Transaction = typeof transactions.$inferSelect;
export type Agency = typeof agencies.$inferSelect;
export type Job = typeof jobs.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;
export type InsertAccount = z.infer<typeof insertAccountSchema>;
export type InsertCard = z.infer<typeof insertCardSchema>;
export type InsertTransaction = z.infer<typeof insertTransactionSchema>;
export type InsertAgency = z.infer<typeof insertAgencySchema>;
export type InsertJob = z.infer<typeof insertJobSchema>;
