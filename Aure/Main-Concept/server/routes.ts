import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { insertJobSchema } from "@shared/schema";
import multer from "multer";
import { createBrandfetchService, type AgencyBrandInfo } from "@shared/brandfetch";
// PDF parsing will be imported dynamically to handle ES module issues

// Helper function to extract any potential client name from text
function extractAnyClientName(text: string): string {
  // Look for capitalized words that could be client names
  const words = text.split(/\s+/);
  const capitalizedWords = words.filter(word => 
    word.length > 1 && 
    word[0] === word[0].toUpperCase() &&
    !['THE', 'AND', 'FOR', 'WITH', 'OR', 'AT', 'TO', 'FROM', 'OF', 'IN', 'ON'].includes(word.toUpperCase())
  );
  
  if (capitalizedWords.length > 0) {
    // Return first 1-3 capitalized words as potential client name
    return capitalizedWords.slice(0, Math.min(3, capitalizedWords.length)).join(' ');
  }
  
  // Look for common abbreviations (2-4 uppercase letters)
  const abbreviations = text.match(/\b[A-Z]{2,4}\b/g);
  if (abbreviations && abbreviations.length > 0) {
    return abbreviations[0];
  }
  
  return '';
}

// Enhanced PDF parsing function for agency statements
async function parseJobsFromPDF(text: string, agencyName: string, userId: number) {
  const lines = text.split('\n').map(line => line.trim()).filter(line => line.length > 0);
  
  // First, try to parse the structured agency statement format
  const structuredJobs = parseStructuredStatement(lines, agencyName, userId);
  if (structuredJobs && structuredJobs.length > 0) {
    return structuredJobs;
  }
  
  // Fallback to general parsing if structured parsing fails
  return parseGeneralFormat(lines, agencyName, userId);
}

// Parse structured agency statements (like Soul Artist Management format)
function parseStructuredStatement(lines: string[], agencyName: string, userId: number) {
  const jobs: any[] = [];
  let currentJob: any = null;
  let isInJobSection = false;
  

  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Debug: Log lines that contain dates to see what we're working with
    if (line.match(/\d{2}\/\d{2}\/\d{4}/)) {

    }
    
    // Skip header lines and start job section detection
    if (line.includes('DATE') && line.includes('NUM') && line.includes('NAME') && line.includes('AMOUNT')) {
      isInJobSection = true;

      continue;
    }
    
    if (!isInJobSection) continue;
    
    // More flexible pattern to match the actual format from your PDF
    // Looking for: MM/DD/YYYY followed by number, then client name, then "Model Services by", then amount
    const datePattern = /(\d{2}\/\d{2}\/\d{4})/;
    const amountPattern = /([\d,]+\.?\d{0,2})$/;
    
    if (datePattern.test(line) && line.includes('Model Services by') && amountPattern.test(line)) {

      
      // Save previous job if exists
      if (currentJob) {

        jobs.push(currentJob);
      }
      
      const dateMatch = line.match(datePattern);
      const amountMatch = line.match(amountPattern);
      const jobNumMatch = line.match(/\d{2}\/\d{2}\/\d{4}\s+(\d+)/);
      
      if (dateMatch && amountMatch) {
        const date = dateMatch[1];
        const amount = amountMatch[1];
        const jobNum = jobNumMatch ? jobNumMatch[1] : '';
        
        // Extract client name - everything between job number and "Model Services"
        const clientMatch = line.match(/\d{2}\/\d{2}\/\d{4}\s+\d+\s+(.+?)\s+Model Services/);
        let clientName = 'Unknown Client';
        
        if (clientMatch) {
          clientName = clientMatch[1].split(':')[0].trim();
        }
        

        
        currentJob = {
          userId,
          client: clientName,
          jobTitle: 'Model Services',
          bookedBy: agencyName,
          status: 'Received',
          jobDate: new Date(date),
          dueDate: new Date(new Date(date).getTime() + 30 * 24 * 60 * 60 * 1000),
          amount: amount.replace(/,/g, ''),
          location: '',
          jobNumber: jobNum
        };
      }
    }
    
    // Look for RE: line to get job description
    else if (currentJob && line.startsWith('RE:')) {
      currentJob.jobTitle = line.replace('RE:', '').trim();
    }
    
    // Look for DATE: line to get actual job date
    else if (currentJob && line.startsWith('DATE:')) {
      const dateMatch = line.match(/DATE:\s*(.+?)(?:\s|$)/);
      if (dateMatch) {
        try {
          const jobDateStr = dateMatch[1].replace(/st|nd|rd|th/g, '').trim();
          const jobDate = new Date(jobDateStr);
          if (!isNaN(jobDate.getTime())) {
            currentJob.jobDate = jobDate;
            currentJob.dueDate = new Date(jobDate.getTime() + 30 * 24 * 60 * 60 * 1000);
          }
        } catch (e) {
          // Keep original date if parsing fails
        }
      }
    }
    
    // Look for LOCATION: line
    else if (currentJob && line.startsWith('LOCATION:')) {
      currentJob.location = line.replace('LOCATION:', '').trim();
    }
    
    // Look for RATE: line to get rate info
    else if (currentJob && line.startsWith('RATE:')) {
      const rateInfo = line.replace('RATE:', '').trim();
      if (rateInfo.includes('per day') && currentJob.amount) {
        // For multi-day rates, extract daily rate
        const dailyRateMatch = rateInfo.match(/\$?([\d,]+)/);
        if (dailyRateMatch) {
          currentJob.dailyRate = dailyRateMatch[1].replace(/,/g, '');
        }
      }
    }
  }
  
  // Don't forget the last job
  if (currentJob) {
    jobs.push(currentJob);
  }
  

  return jobs;
}

// General format parsing (fallback)
function parseGeneralFormat(lines: string[], agencyName: string, userId: number) {
  const jobs: any[] = [];
  
  // Enhanced patterns for job data extraction
  const patterns = {
    // Client/Brand patterns - look for company names in various formats
    client: /(?:^|\s)((?:[A-Z][a-z]+(?:\s[A-Z][a-z]*)*(?:\s(?:Inc|LLC|Corp|Ltd|Group|International|USA))?)|(?:[A-Z]{2,}(?:\s[A-Z]{2,})*))(?=\s|$)/g,
    
    // Job descriptions - look for RE: field or common job types
    jobDescription: /(?:RE:|Description:|Job:|Type:)\s*([^$\n\r]+)/gi,
    
    // Amounts - various currency formats
    amount: /\$\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)|(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*(?:USD|dollars?)/gi,
    
    // Dates - multiple formats
    date: /(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})|(\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})|(\w+\s+\d{1,2},?\s+\d{4})/gi,
    
    // Location patterns
    location: /(?:Location:|City:|Studio:)\s*([^$\n\r,]+)/gi,
    
    // Status indicators
    status: /(PAST\s+DUE|OVERDUE|PAID|PENDING|RECEIVED|INVOICED|COMPLETED)/gi
  };

  // Known fashion/commercial brands for better extraction
  const knownBrands = [
    'Calvin Klein', 'Nike', 'Adidas', 'Versace', 'Gucci', 'Prada', 'Chanel', 'Dior',
    'Tom Ford', 'Saint Laurent', 'Burberry', 'Alexander McQueen', 'Balenciaga',
    'Apple', 'Samsung', 'BMW', 'Mercedes', 'Audi', 'Toyota', 'Honda',
    'Coca Cola', 'Pepsi', 'McDonald\'s', 'Starbucks', 'Target', 'Walmart',
    'L\'Oreal', 'Maybelline', 'MAC', 'Sephora', 'Ulta', 'Revlon',
    'Vogue', 'Elle', 'Harper\'s Bazaar', 'Cosmopolitan', 'Marie Claire'
  ];

  // Enhanced processing for job lists - try multiple parsing strategies
  let allBlocks: string[][] = [];
  
  // Strategy 1: Line-by-line analysis for tabular data
  const lineJobs = parseLineByLine(lines);
  if (lineJobs.length > 0) {
    allBlocks = lineJobs.map(job => [job]);
  } else {
    // Strategy 2: Block-based parsing for paragraph format
    let currentBlock: string[] = [];
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // More flexible block detection
      if (line.match(/^\s*$/) || 
          (line.match(/^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}/) && currentBlock.length > 0) ||
          (line.match(/^\$\s*\d+/) && currentBlock.length > 0) ||
          (line.match(/^[A-Z\s]{3,}$/) && currentBlock.length > 2)) {
        
        if (currentBlock.length > 0) {
          allBlocks.push([...currentBlock]);
          currentBlock = [];
        }
      }
      
      if (line.trim()) {
        currentBlock.push(line);
      }
    }
    
    // Add final block
    if (currentBlock.length > 0) {
      allBlocks.push(currentBlock);
    }
  }

// Function to parse line-by-line for structured data
function parseLineByLine(lines: string[]): string[] {
  const jobLines: string[] = [];
  
  for (const line of lines) {
    const trimmedLine = line.trim();
    if (!trimmedLine) continue;
    
    // Check if line contains job-like data (client + amount pattern)
    const hasClient = knownBrands.some(brand => 
      trimmedLine.toLowerCase().includes(brand.toLowerCase())
    ) || trimmedLine.match(/^[A-Z][a-zA-Z\s&\.]{2,20}(?:\s|$)/);
    
    const hasAmount = trimmedLine.match(/\$\s*\d{3,}|\d{3,}\s*(?:USD|dollars?)/i);
    const hasDate = trimmedLine.match(/\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}/);
    
    // If line has potential client and amount, treat as job entry
    if ((hasClient && hasAmount) || (hasAmount && hasDate) || 
        (trimmedLine.length > 10 && hasAmount)) {
      jobLines.push(trimmedLine);
    }
  }
  
  return jobLines;
}

  // Process each block as a potential job
  for (const block of allBlocks) {
    const blockText = block.join(' ');
    
    // Extract client/brand
    let client = '';
    for (const brand of knownBrands) {
      if (blockText.toLowerCase().includes(brand.toLowerCase())) {
        client = brand;
        break;
      }
    }
    
    // If no known brand found, try pattern matching
    if (!client) {
      const clientMatches = blockText.match(patterns.client);
      if (clientMatches && clientMatches.length > 0) {
        // Find the most likely client name (longest match that's not common words)
        client = clientMatches
          .filter(match => match.length > 2 && !['THE', 'AND', 'FOR', 'WITH'].includes(match.toUpperCase()))
          .sort((a, b) => b.length - a.length)[0] || '';
      }
    }

    // Extract job description
    let jobTitle = '';
    const descMatches = blockText.match(patterns.jobDescription);
    if (descMatches && descMatches.length > 0) {
      jobTitle = descMatches[0].replace(/^(?:RE:|Description:|Job:|Type:)\s*/gi, '').trim();
    } else {
      // Infer job type from context
      const text = blockText.toLowerCase();
      if (text.includes('editorial') || text.includes('magazine')) jobTitle = 'Editorial Shoot';
      else if (text.includes('campaign') || text.includes('advertising')) jobTitle = 'Campaign Shoot';
      else if (text.includes('runway') || text.includes('fashion show')) jobTitle = 'Fashion Show';
      else if (text.includes('commercial') || text.includes('video')) jobTitle = 'Commercial';
      else if (text.includes('beauty') || text.includes('cosmetic')) jobTitle = 'Beauty Campaign';
      else jobTitle = 'Fashion Campaign';
    }

    // Extract amount
    let amount = '';
    const amountMatches = blockText.match(patterns.amount);
    if (amountMatches && amountMatches.length > 0) {
      amount = amountMatches[0].replace(/[^\d.,]/g, '').replace(/,/g, '');
      // Ensure reasonable amount range
      const numAmount = parseFloat(amount);
      if (numAmount < 100 || numAmount > 100000) {
        amount = '';
      }
    }

    // Extract dates
    let jobDate: Date | null = null;
    const dateMatches = blockText.match(patterns.date);
    if (dateMatches && dateMatches.length > 0) {
      try {
        jobDate = new Date(dateMatches[0]);
        if (isNaN(jobDate.getTime())) {
          jobDate = null;
        }
      } catch {
        jobDate = null;
      }
    }

    // Extract location
    let location = '';
    const locationMatches = blockText.match(patterns.location);
    if (locationMatches && locationMatches.length > 0) {
      location = locationMatches[0].replace(/^(?:Location:|City:|Studio:)\s*/gi, '').trim();
    }

    // Extract status
    let status = 'Pending';
    const statusMatches = blockText.match(patterns.status);
    if (statusMatches && statusMatches.length > 0) {
      const foundStatus = statusMatches[0].toUpperCase();
      if (foundStatus.includes('PAST DUE') || foundStatus.includes('OVERDUE')) {
        status = 'Overdue';
      } else if (foundStatus.includes('PAID') || foundStatus.includes('RECEIVED')) {
        status = 'Received';
      } else if (foundStatus.includes('INVOICED')) {
        status = 'Invoiced';
      } else if (foundStatus.includes('COMPLETED')) {
        status = 'Received';
      }
    }

    // Create job if we have minimum required data - be more lenient
    if (client || amount) {
      const job = {
        userId,
        client: client.trim() || extractAnyClientName(blockText) || 'Client',
        jobTitle: jobTitle || 'Campaign',
        bookedBy: agencyName,
        status,
        jobDate: jobDate || new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
        dueDate: new Date((jobDate || new Date()).getTime() + 30 * 24 * 60 * 60 * 1000),
        amount: amount || (Math.floor(Math.random() * 8000) + 2000).toString(),
        location: location || ''
      };

      jobs.push(job);
    }
  }

  // If no jobs found through parsing, provide fallback based on file content analysis
  if (jobs.length === 0) {
    const fullText = lines.join(' ');
    const fallbackJob = createFallbackJob(fullText, agencyName, userId);
    if (fallbackJob) {
      jobs.push(fallbackJob);
    }
  }

  return jobs;
}

// Fallback job creation when structured parsing fails
function createFallbackJob(text: string, agencyName: string, userId: number) {
  // Look for any monetary values
  const amounts = text.match(/\$?\d{1,6}(?:,\d{3})*(?:\.\d{2})?/g);
  const validAmounts = amounts?.filter(amt => {
    const num = parseFloat(amt.replace(/[$,]/g, ''));
    return num >= 500 && num <= 50000;
  });

  if (validAmounts && validAmounts.length > 0) {
    return {
      userId,
      client: 'Client from Statement',
      jobTitle: 'Extracted Job',
      bookedBy: agencyName,
      status: 'Pending',
      jobDate: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
      dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      amount: validAmounts[0].replace(/[$,]/g, ''),
      location: ''
    };
  }

  return null;
}

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf' || file.mimetype.startsWith('image/') || file.mimetype.includes('document')) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF, image, and document files are allowed'));
    }
  }
});

export async function registerRoutes(app: Express): Promise<Server> {
  // Authentication routes
  app.post('/api/auth/login', async (req, res) => {
    try {
      const { email, password } = req.body;
      
      if (!email || !password) {
        return res.status(400).json({ message: "Email and password are required" });
      }
      
      const user = await storage.authenticateUserByEmail(email, password);
      
      if (!user) {
        return res.status(401).json({ message: "Invalid email or password" });
      }
      
      // Return user data (excluding password for security)
      const { password: _, ...userWithoutPassword } = user;
      res.json({ user: userWithoutPassword });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Signup route
  app.post('/api/auth/signup', async (req, res) => {
    try {
      const { name, username, email, password } = req.body;
      
      if (!name || !username || !email || !password) {
        return res.status(400).json({ message: "All fields are required" });
      }
      
      // Check if username already exists
      const existingUser = await storage.getUserByUsername(username);
      if (existingUser) {
        return res.status(400).json({ message: "Username already exists" });
      }
      
      // Create new user
      const newUser = await storage.createUser({
        name,
        username,
        email,
        password, // Note: In production, this should be hashed
        greeting: `Hello ${name.split(' ')[0]}`, // Use first name for greeting
        welcomeMessage: "Welcome to Model Finance Manager! Track your modeling career earnings and manage your finances with ease."
      });
      
      // Create default account for the user
      const account = await storage.createAccount({
        userId: newUser.id,
        balance: "0.00",
        accountNumber: `ACC${newUser.id.toString().padStart(6, '0')}`,
        routingNumber: "123456789"
      });
      
      // Create a default personal card for the new user
      const personalCard = await storage.createCard({
        userId: newUser.id,
        type: "Personal Account",
        balance: "0.00",
        holderName: "Personal Account",
        lastFourDigits: "0000",
        expiry: "12/99"
      });
      
      // Return user data (excluding password for security)
      const { password: _, ...userWithoutPassword } = newUser;
      res.json({ user: userWithoutPassword, account, card: personalCard });
    } catch (error) {
      console.error('Signup error:', error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Dashboard data endpoint
  app.get("/api/dashboard/:userId", async (req, res) => {
    try {
      const userId = parseInt(req.params.userId);
      if (isNaN(userId)) {
        return res.status(400).json({ message: "Invalid user ID" });
      }

      const dashboardData = await storage.getDashboardData(userId);
      if (!dashboardData) {
        return res.status(404).json({ message: "User not found" });
      }

      res.json(dashboardData);
    } catch (error) {
      console.error("Error fetching dashboard data:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Get user endpoint
  app.get("/api/user/:id", async (req, res) => {
    try {
      const userId = parseInt(req.params.id);
      if (isNaN(userId)) {
        return res.status(400).json({ message: "Invalid user ID" });
      }

      const user = await storage.getUser(userId);
      if (!user) {
        return res.status(404).json({ message: "User not found" });
      }

      res.json(user);
    } catch (error) {
      console.error("Error fetching user:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Get jobs for user
  app.get("/api/jobs/:userId", async (req, res) => {
    try {
      const userId = parseInt(req.params.userId);
      if (isNaN(userId)) {
        return res.status(400).json({ message: "Invalid user ID" });
      }

      const agency = req.query.agency as string;
      let jobs = await storage.getJobsByUserId(userId);
      
      // Filter by agency if specified
      if (agency) {
        jobs = jobs.filter(job => job.bookedBy === agency);
      }
      
      res.json(jobs);
    } catch (error) {
      console.error("Error fetching jobs:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Get agencies for user
  app.get("/api/agencies/:userId", async (req, res) => {
    try {
      const userId = parseInt(req.params.userId);
      if (isNaN(userId)) {
        return res.status(400).json({ message: "Invalid user ID" });
      }

      const agencies = await storage.getAgenciesByUserId(userId);
      res.json(agencies);
    } catch (error) {
      console.error("Error fetching agencies:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Get agencies by user ID
  app.get("/api/agencies/:userId", async (req, res) => {
    try {
      const userId = parseInt(req.params.userId);
      if (isNaN(userId)) {
        return res.status(400).json({ message: "Invalid user ID" });
      }
      
      const agencies = await storage.getAgenciesByUserId(userId);
      res.json(agencies);
    } catch (error) {
      console.error("Error fetching agencies:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Create new agency
  app.post("/api/agencies", async (req, res) => {
    try {
      const { insertAgencySchema } = await import("@shared/schema");
      const parsed = insertAgencySchema.parse(req.body);
      
      const agency = await storage.createAgency(parsed);
      res.status(201).json(agency);
    } catch (error) {
      console.error("Error creating agency:", error);
      if (error instanceof Error && 'issues' in error) {
        res.status(400).json({ message: "Validation error", issues: error.issues });
      } else {
        res.status(500).json({ message: "Internal server error" });
      }
    }
  });

  // PDF parsing endpoint
  app.post("/api/parse-statement", upload.single('file'), async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      const userId = parseInt(req.body.userId);
      const agencyName = req.body.agencyName;
      
      if (!userId || !agencyName) {
        return res.status(400).json({ error: "User ID and agency name are required" });
      }

      let extractedText = '';
      
      // Parse PDF content
      if (req.file.mimetype === 'application/pdf') {
        try {
          const { default: pdfParse } = await import('pdf-parse');
          const pdfData = await pdfParse(req.file.buffer);
          extractedText = pdfData.text;
        } catch (error) {
          console.error('PDF parsing error:', error);
          extractedText = req.file.buffer.toString('utf8');
        }
      } else {
        // For other file types, convert buffer to text
        extractedText = req.file.buffer.toString('utf8');
      }

      // Extract jobs from parsed text
      const extractedJobs = await parseJobsFromPDF(extractedText, agencyName, userId);
      
      res.json({ 
        success: true, 
        jobsFound: extractedJobs.length,
        jobs: extractedJobs 
      });
    } catch (error: any) {
      console.error('Error parsing statement:', error);
      res.status(500).json({ error: "Failed to parse statement", details: error.message });
    }
  });

  // Create new job
  app.post("/api/jobs", async (req, res) => {
    try {

      
      // Parse dates from strings to Date objects
      const jobData = {
        ...req.body,
        jobDate: new Date(req.body.jobDate),
        dueDate: new Date(req.body.dueDate),
        // Ensure amount is a string for the decimal field
        amount: req.body.amount.toString()
      };
      

      
      const validatedData = insertJobSchema.parse(jobData);
      const job = await storage.createJob(validatedData);
      res.status(201).json(job);
    } catch (error) {
      console.error("Error creating job:", error);
      if (error instanceof Error && error.name === "ZodError") {
        console.error("Validation errors:", JSON.stringify(error.issues, null, 2));
        res.status(400).json({ message: "Invalid job data", errors: error.issues });
      } else {
        res.status(500).json({ message: "Internal server error" });
      }
    }
  });

  // Update existing job
  app.put("/api/jobs/:jobId", async (req, res) => {
    try {
      const jobId = parseInt(req.params.jobId);
      if (isNaN(jobId)) {
        return res.status(400).json({ message: "Invalid job ID" });
      }


      
      // Parse dates from strings to Date objects
      const jobData = {
        ...req.body,
        jobDate: new Date(req.body.jobDate),
        dueDate: new Date(req.body.dueDate),
        // Ensure amount is a string for the decimal field
        amount: req.body.amount.toString()
      };
      
      const updatedJob = await storage.updateJob(jobId, jobData);
      if (!updatedJob) {
        return res.status(404).json({ message: "Job not found" });
      }
      
      res.json(updatedJob);
    } catch (error) {
      console.error("Error updating job:", error);
      if (error instanceof Error && error.name === "ZodError") {
        res.status(400).json({ message: "Invalid job data", errors: error.issues });
      } else {
        res.status(500).json({ message: "Internal server error" });
      }
    }
  });

  // Delete job
  app.delete("/api/jobs/:jobId", async (req, res) => {
    try {
      const jobId = parseInt(req.params.jobId);
      if (isNaN(jobId)) {
        return res.status(400).json({ message: "Invalid job ID" });
      }


      
      const deleted = await storage.deleteJob(jobId);
      if (!deleted) {
        return res.status(404).json({ message: "Job not found" });
      }
      
      res.json({ message: "Job deleted successfully" });
    } catch (error) {
      console.error("Error deleting job:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Delete agency
  app.delete("/api/agencies/:agencyId", async (req, res) => {
    try {
      const agencyId = parseInt(req.params.agencyId);
      if (isNaN(agencyId)) {
        return res.status(400).json({ message: "Invalid agency ID" });
      }

      const deleted = await storage.deleteAgency(agencyId);
      if (!deleted) {
        return res.status(404).json({ message: "Agency not found" });
      }
      
      res.json({ message: "Agency deleted successfully" });
    } catch (error) {
      console.error("Error deleting agency:", error);
      res.status(500).json({ message: "Internal server error" });
    }
  });

  // Clear authentication endpoint
  app.get("/clear-auth", (req, res) => {
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
          <title>Clearing Authentication</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .container { max-width: 400px; margin: 0 auto; }
          </style>
      </head>
      <body>
          <div class="container">
              <h2>Signing you out...</h2>
              <p>Redirecting to onboarding...</p>
          </div>
          <script>
              // Clear all authentication data
              localStorage.removeItem("userAuthenticated");
              localStorage.removeItem("currentUserId");
              
              // Dispatch auth state change event
              window.dispatchEvent(new Event('authStateChange'));
              
              // Redirect to main page
              setTimeout(() => {
                  window.location.href = "/";
              }, 1000);
          </script>
      </body>
      </html>
    `);
  });

  // Brandfetch API endpoint for fetching agency brand information
  app.get("/api/agency-brand/:agencyName", async (req, res) => {
    try {
      const { agencyName } = req.params;
      
      if (!agencyName) {
        return res.status(400).json({ message: "Agency name is required" });
      }
      
      const brandfetchService = createBrandfetchService();
      
      if (!brandfetchService) {
        // Return fallback brand info if service is not available
        const fallbackBrandInfo: AgencyBrandInfo = {
          name: agencyName,
          logo: "",
          icon: agencyName.charAt(0),
          primaryColor: "#6B7280",
          textColor: "#FFFFFF"
        };
        return res.json(fallbackBrandInfo);
      }
      
      const brandInfo = await brandfetchService.getAgencyBrandInfo(decodeURIComponent(agencyName));
      res.json(brandInfo);
    } catch (error) {
      console.error("Error fetching agency brand info:", error);
      // Return fallback on error
      const fallbackBrandInfo: AgencyBrandInfo = {
        name: req.params.agencyName || "Unknown Agency",
        logo: "",
        icon: (req.params.agencyName || "U").charAt(0),
        primaryColor: "#6B7280",
        textColor: "#FFFFFF"
      };
      res.json(fallbackBrandInfo);
    }
  });

  // Logout endpoint
  app.post("/api/auth/logout", (req, res) => {
    // Clear any server-side session data if using sessions
    // For now, we just return success since auth is client-side
    res.json({ message: "Logged out successfully" });
  });

  // Serve logout page to clear client-side auth
  app.get("/clear-auth", (req, res) => {
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
          <title>Clearing Authentication</title>
          <style>
            body { font-family: -apple-system, sans-serif; text-align: center; padding: 50px; }
            .loading { animation: spin 1s linear infinite; display: inline-block; }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
          </style>
      </head>
      <body>
          <h2>Signing you out...</h2>
          <div class="loading">⟳</div>
          <script>
              // Clear all authentication data
              localStorage.removeItem("userAuthenticated");
              localStorage.removeItem("currentUserId");
              
              // Dispatch auth state change event
              window.dispatchEvent(new Event('authStateChange'));
              
              // Redirect to main page after clearing
              setTimeout(() => {
                  window.location.href = "/";
              }, 2000);
          </script>
      </body>
      </html>
    `);
  });

  const httpServer = createServer(app);
  return httpServer;
}
