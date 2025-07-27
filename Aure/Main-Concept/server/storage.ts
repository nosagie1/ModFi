import { users, accounts, cards, transactions, jobs, agencies, type User, type Account, type Card, type Transaction, type Job, type Agency, type InsertUser, type InsertAccount, type InsertCard, type InsertTransaction, type InsertJob, type InsertAgency } from "@shared/schema";
import { db } from "./db";
import { eq, and } from "drizzle-orm";

export interface IStorage {
  getUser(id: number): Promise<User | undefined>;
  getUserByName(name: string): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  getUserByEmail(email: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  authenticateUser(username: string, password: string): Promise<User | undefined>;
  authenticateUserByEmail(email: string, password: string): Promise<User | undefined>;
  
  getAccountByUserId(userId: number): Promise<Account | undefined>;
  createAccount(account: InsertAccount): Promise<Account>;
  
  getCardsByUserId(userId: number): Promise<Card[]>;
  createCard(card: InsertCard): Promise<Card>;
  
  getTransactionsByUserId(userId: number): Promise<Transaction[]>;
  createTransaction(transaction: InsertTransaction): Promise<Transaction>;
  
  getJobsByUserId(userId: number): Promise<Job[]>;
  createJob(job: InsertJob): Promise<Job>;
  updateJob(jobId: number, job: Partial<Job>): Promise<Job | null>;
  deleteJob(jobId: number): Promise<boolean>;
  
  getAgenciesByUserId(userId: number): Promise<Agency[]>;
  createAgency(agency: InsertAgency): Promise<Agency>;
  deleteAgency(agencyId: number): Promise<boolean>;
  
  getDashboardData(userId: number): Promise<{
    user: User;
    account: Account;
    cards: Card[];
    transactions: Transaction[];
  } | undefined>;
}

export class MemStorage implements IStorage {
  private users: Map<number, User>;
  private accounts: Map<number, Account>;
  private cards: Map<number, Card>;
  private transactions: Map<number, Transaction>;
  private jobs: Map<number, Job>;
  private agencies: Map<number, Agency>;
  private userIdCounter: number;
  private accountIdCounter: number;
  private cardIdCounter: number;
  private transactionIdCounter: number;
  private jobIdCounter: number;
  private agencyIdCounter: number;

  constructor() {
    this.users = new Map();
    this.accounts = new Map();
    this.cards = new Map();
    this.transactions = new Map();
    this.jobs = new Map();
    this.agencies = new Map();
    this.userIdCounter = 1;
    this.accountIdCounter = 1;
    this.cardIdCounter = 1;
    this.transactionIdCounter = 1;
    this.jobIdCounter = 1;
    this.agencyIdCounter = 1;

    // Initialize with mock data
    this.initializeMockData();
  }

  private async initializeMockData() {
    // Create user
    const user = await this.createUser({
      name: "Kwaku",
      username: "Kwakuansong",
      email: "kwaku@example.com",
      password: "Test123",
      greeting: "Hello Kwaku",
      welcomeMessage: "Welcome Back"
    });

    // Create account
    await this.createAccount({
      userId: user.id,
      balance: "10340.98"
    });

    // Create cards
    await this.createCard({
      userId: user.id,
      holderName: "Soul Artist Management",
      lastFourDigits: "6838",
      expiry: "06/26",
      type: "Apple Card"
    });

    await this.createCard({
      userId: user.id,
      holderName: "Wilhelmina London",
      lastFourDigits: "2847",
      expiry: "12/28",
      type: "Business Card"
    });

    await this.createCard({
      userId: user.id,
      holderName: "Personal Account",
      lastFourDigits: "1356",
      expiry: "09/27",
      type: "Debit Card"
    });

    // Create transactions - modeling agency payments
    const transactionData = [
      {
        userId: user.id,
        merchant: "ELITE Model Management",
        amount: "4750.50",
        paymentMethod: "Bank Transfer",
        date: new Date("2024-06-30"),
        icon: "crown",
        iconColor: "text-purple-600"
      },
      {
        userId: user.id,
        merchant: "Wilhelmina London",
        amount: "3290.25",
        paymentMethod: "Direct Deposit",
        date: new Date("2024-06-27"),
        icon: "star",
        iconColor: "text-blue-500"
      },
      {
        userId: user.id,
        merchant: "WHY NOT Management",
        amount: "2300.23",
        paymentMethod: "Wire Transfer",
        date: new Date("2024-06-25"),
        icon: "diamond",
        iconColor: "text-gray-600"
      },
      {
        userId: user.id,
        merchant: "Calvin Klein",
        amount: "1250.00",
        paymentMethod: "Bank Transfer",
        date: new Date("2024-06-20"),
        icon: "crown",
        iconColor: "text-purple-600"
      },
      {
        userId: user.id,
        merchant: "Louis Vuitton",
        amount: "2100.75",
        paymentMethod: "Wire Transfer",
        date: new Date("2024-06-15"),
        icon: "star",
        iconColor: "text-blue-500"
      },
      {
        userId: user.id,
        merchant: "Chanel",
        amount: "1850.00",
        paymentMethod: "Direct Deposit",
        date: new Date("2024-06-10"),
        icon: "diamond",
        iconColor: "text-gray-600"
      },
      {
        userId: user.id,
        merchant: "Versace",
        amount: "3200.50",
        paymentMethod: "Bank Transfer",
        date: new Date("2024-06-05"),
        icon: "crown",
        iconColor: "text-purple-600"
      },
      {
        userId: user.id,
        merchant: "Dior",
        amount: "2750.25",
        paymentMethod: "Wire Transfer",
        date: new Date("2024-05-30"),
        icon: "star",
        iconColor: "text-blue-500"
      }
    ];

    for (const transaction of transactionData) {
      await this.createTransaction(transaction);
    }
  }

  async getUser(id: number): Promise<User | undefined> {
    return this.users.get(id);
  }

  async getUserByName(name: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(user => user.name === name);
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(user => user.username === username);
  }

  async getUserByEmail(email: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(user => user.email === email);
  }

  async authenticateUser(username: string, password: string): Promise<User | undefined> {
    const user = Array.from(this.users.values()).find(user => user.username === username);
    if (user && user.password === password) {
      return user;
    }
    return undefined;
  }

  async authenticateUserByEmail(email: string, password: string): Promise<User | undefined> {
    const user = Array.from(this.users.values()).find(user => user.email === email);
    if (user && user.password === password) {
      return user;
    }
    return undefined;
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const id = this.userIdCounter++;
    const user: User = { ...insertUser, id };
    this.users.set(id, user);
    return user;
  }

  async getAccountByUserId(userId: number): Promise<Account | undefined> {
    return Array.from(this.accounts.values()).find(account => account.userId === userId);
  }

  async createAccount(insertAccount: InsertAccount): Promise<Account> {
    const id = this.accountIdCounter++;
    const account: Account = { ...insertAccount, id };
    this.accounts.set(id, account);
    return account;
  }

  async getCardsByUserId(userId: number): Promise<Card[]> {
    return Array.from(this.cards.values()).filter(card => card.userId === userId);
  }

  async createCard(insertCard: InsertCard): Promise<Card> {
    const id = this.cardIdCounter++;
    const card: Card = { 
      ...insertCard, 
      id,
      balance: insertCard.balance || "0.00"
    };
    this.cards.set(id, card);
    return card;
  }

  async getTransactionsByUserId(userId: number): Promise<Transaction[]> {
    return Array.from(this.transactions.values())
      .filter(transaction => transaction.userId === userId)
      .sort((a, b) => b.date.getTime() - a.date.getTime());
  }

  async createTransaction(insertTransaction: InsertTransaction): Promise<Transaction> {
    const id = this.transactionIdCounter++;
    const transaction: Transaction = { ...insertTransaction, id };
    this.transactions.set(id, transaction);
    return transaction;
  }

  async getJobsByUserId(userId: number): Promise<Job[]> {
    return Array.from(this.jobs.values())
      .filter(job => job.userId === userId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  async createJob(insertJob: InsertJob): Promise<Job> {
    const id = this.jobIdCounter++;
    const job: Job = { 
      ...insertJob, 
      id, 
      createdAt: new Date(),
      jobTitle: insertJob.jobTitle || null,
      agencyId: insertJob.agencyId || null
    };
    this.jobs.set(id, job);
    return job;
  }

  async updateJob(jobId: number, updates: Partial<Job>): Promise<Job | null> {
    const existingJob = this.jobs.get(jobId);
    if (!existingJob) {
      return null;
    }

    const updatedJob: Job = {
      ...existingJob,
      ...updates,
      id: jobId // Ensure ID doesn't change
    };
    
    this.jobs.set(jobId, updatedJob);
    return updatedJob;
  }

  async deleteJob(jobId: number): Promise<boolean> {
    return this.jobs.delete(jobId);
  }

  async getAgenciesByUserId(userId: number): Promise<Agency[]> {
    return Array.from(this.agencies.values())
      .filter(agency => agency.userId === userId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  async createAgency(insertAgency: InsertAgency): Promise<Agency> {
    const id = this.agencyIdCounter++;
    const agency: Agency = { 
      ...insertAgency, 
      id, 
      createdAt: new Date(),
      currency: insertAgency.currency || "USD"
    };
    this.agencies.set(id, agency);
    
    // Automatically create a corresponding card for the new agency
    const cardId = this.cardIdCounter++;
    const newCard: Card = {
      id: cardId,
      userId: insertAgency.userId,
      type: "Agency Card",
      balance: "0.00",
      holderName: insertAgency.name,
      lastFourDigits: "0000",
      expiry: "12/99"
    };
    this.cards.set(cardId, newCard);
    
    return agency;
  }

  async deleteAgency(agencyId: number): Promise<boolean> {
    const agency = this.agencies.get(agencyId);
    if (!agency) {
      return false;
    }

    // Delete the agency
    this.agencies.delete(agencyId);

    // Delete corresponding card
    const cardToDelete = Array.from(this.cards.values())
      .find(card => card.holderName === agency.name && card.userId === agency.userId);
    if (cardToDelete) {
      this.cards.delete(cardToDelete.id);
    }

    // Delete jobs associated with this agency
    const jobsToDelete = Array.from(this.jobs.values())
      .filter(job => job.bookedBy === agency.name && job.userId === agency.userId);
    jobsToDelete.forEach(job => this.jobs.delete(job.id));

    return true;
  }

  async getDashboardData(userId: number): Promise<{
    user: User;
    account: Account;
    cards: Card[];
    transactions: Transaction[];
  } | undefined> {
    const user = await this.getUser(userId);
    if (!user) return undefined;

    const account = await this.getAccountByUserId(userId);
    const cards = await this.getCardsByUserId(userId);
    const transactions = await this.getTransactionsByUserId(userId);

    if (!account) return undefined;

    return {
      user,
      account,
      cards,
      transactions
    };
  }
}

// DatabaseStorage implementation
export class DatabaseStorage implements IStorage {
  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user || undefined;
  }

  async getUserByName(name: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.name, name));
    return user || undefined;
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user || undefined;
  }

  async getUserByEmail(email: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.email, email));
    return user || undefined;
  }

  async authenticateUser(username: string, password: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    if (user && user.password === password) {
      return user;
    }
    return undefined;
  }

  async authenticateUserByEmail(email: string, password: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.email, email));
    if (user && user.password === password) {
      return user;
    }
    return undefined;
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const [user] = await db
      .insert(users)
      .values(insertUser)
      .returning();
    return user;
  }

  async getAccountByUserId(userId: number): Promise<Account | undefined> {
    const [account] = await db.select().from(accounts).where(eq(accounts.userId, userId));
    return account || undefined;
  }

  async createAccount(insertAccount: InsertAccount): Promise<Account> {
    const [account] = await db
      .insert(accounts)
      .values(insertAccount)
      .returning();
    return account;
  }

  async getCardsByUserId(userId: number): Promise<Card[]> {
    return await db.select().from(cards).where(eq(cards.userId, userId));
  }

  async createCard(insertCard: InsertCard): Promise<Card> {
    const [card] = await db
      .insert(cards)
      .values(insertCard)
      .returning();
    return card;
  }

  async getTransactionsByUserId(userId: number): Promise<Transaction[]> {
    return await db.select().from(transactions)
      .where(eq(transactions.userId, userId))
      .orderBy((transactions.date));
  }

  async createTransaction(insertTransaction: InsertTransaction): Promise<Transaction> {
    const [transaction] = await db
      .insert(transactions)
      .values(insertTransaction)
      .returning();
    return transaction;
  }

  async getJobsByUserId(userId: number): Promise<Job[]> {
    const result = await db.select().from(jobs)
      .where(eq(jobs.userId, userId));
    
    // Sort by createdAt in descending order (newest first)
    return result.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  async createJob(insertJob: InsertJob): Promise<Job> {
    const [job] = await db
      .insert(jobs)
      .values(insertJob)
      .returning();
    return job;
  }

  async updateJob(jobId: number, updates: Partial<Job>): Promise<Job | null> {
    const [updatedJob] = await db
      .update(jobs)
      .set(updates)
      .where(eq(jobs.id, jobId))
      .returning();
    
    return updatedJob || null;
  }

  async deleteJob(jobId: number): Promise<boolean> {
    const result = await db
      .delete(jobs)
      .where(eq(jobs.id, jobId));
    
    return (result.rowCount || 0) > 0;
  }

  async getAgenciesByUserId(userId: number): Promise<Agency[]> {
    const result = await db.select().from(agencies)
      .where(eq(agencies.userId, userId));
    
    return result.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  async createAgency(insertAgency: InsertAgency): Promise<Agency> {
    const [agency] = await db
      .insert(agencies)
      .values(insertAgency)
      .returning();
    return agency;
  }

  async deleteAgency(agencyId: number): Promise<boolean> {
    const agency = await db.select().from(agencies).where(eq(agencies.id, agencyId)).limit(1);
    if (agency.length === 0) {
      return false;
    }

    // Delete jobs associated with this agency first
    await db.delete(jobs).where(and(
      eq(jobs.bookedBy, agency[0].name),
      eq(jobs.userId, agency[0].userId)
    ));

    // Delete corresponding cards
    await db.delete(cards).where(and(
      eq(cards.holderName, agency[0].name),
      eq(cards.userId, agency[0].userId)
    ));

    // Delete the agency
    await db.delete(agencies).where(eq(agencies.id, agencyId));
    
    return true;
  }

  async getDashboardData(userId: number): Promise<{
    user: User;
    account: Account;
    cards: Card[];
    transactions: Transaction[];
  } | undefined> {
    const user = await this.getUser(userId);
    if (!user) return undefined;

    const account = await this.getAccountByUserId(userId);
    const cards = await this.getCardsByUserId(userId);
    const transactions = await this.getTransactionsByUserId(userId);

    if (!account) return undefined;

    return {
      user,
      account,
      cards,
      transactions
    };
  }
}

// Initialize database with sample data
async function initializeDatabase() {
  // Check if user already exists
  const existingUser = await db.select().from(users).where(eq(users.name, "Kwaku")).limit(1);
  
  if (existingUser.length === 0) {
    // Create user
    const [user] = await db
      .insert(users)
      .values({
        name: "Kwaku",
        username: "Kwakuansong",
        email: "kwaku@example.com",
        password: "Test123",
        greeting: "Hello Kwaku",
        welcomeMessage: "Welcome Back"
      })
      .returning();

    // Create account
    await db
      .insert(accounts)
      .values({
        userId: user.id,
        balance: "10340.98"
      });

    // Create cards
    await db.insert(cards).values([
      {
        userId: user.id,
        holderName: "Soul Artist Management",
        lastFourDigits: "6838",
        expiry: "06/26",
        type: "Apple Card"
      },
      {
        userId: user.id,
        holderName: "Wilhelmina London",
        lastFourDigits: "2847",
        expiry: "12/28",
        type: "Business Card"
      },
      {
        userId: user.id,
        holderName: "Personal Account",
        lastFourDigits: "1356",
        expiry: "09/27",
        type: "Debit Card"
      }
    ]);

    // Create transactions
    await db.insert(transactions).values([
      {
        userId: user.id,
        merchant: "Figma",
        amount: "144.00",
        paymentMethod: "Visa Card",
        date: new Date("2024-06-30"),
        icon: "figma",
        iconColor: "text-purple-600"
      },
      {
        userId: user.id,
        merchant: "Sketch",
        amount: "-138.00",
        paymentMethod: "Paypal",
        date: new Date("2024-06-27"),
        icon: "gem",
        iconColor: "text-orange-500"
      },
      {
        userId: user.id,
        merchant: "Dribbble",
        amount: "162.00",
        paymentMethod: "Google Pay",
        date: new Date("2024-06-25"),
        icon: "dribbble",
        iconColor: "text-pink-500"
      }
    ]);
  }
}

export const storage = new DatabaseStorage();

// Initialize the database on startup
initializeDatabase().catch(console.error);
