# Product Requirements Document (PRD)

## Project Overview

This document outlines the requirements for developing a web application to replace the existing Excel-based system used at Nevados, a purified water distribution company. The main objectives are to improve the management of daily sales, client data, product details, special pricing, discounts, and future features such as client subscriptions and new products.

### Technology Stack

- **Next.js**: Frontend framework for building React applications with server-side rendering
- **ShadCN**: Library for building reusable UI components
- **Tailwind CSS**: Utility-first CSS framework for styling
- **Lucide Icons**: Icon library for consistent iconography
- **Supabase**: Backend services for database management, authentication, and storage
- **Vercel**: Platform for deploying the frontend application

This stack ensures scalability, security, and ease of use.

## Project File Structure

To maintain simplicity and efficiency, the project will be structured with as few files as possible while ensuring modularity and scalability.

```
nevados-app
├── README.md
├── .env.local
├── next.config.js
├── package.json
├── package-lock.json
├── postcss.config.js
├── tailwind.config.js
├── tsconfig.json
├── public
│   ├── favicon.ico
│   └── assets (for images, fonts, etc.)
├── styles
│   └── globals.css
├── lib
│   ├── supabaseClient.js
│   └── utils.js
├── pages
│   ├── _app.js
│   ├── index.js
│   ├── login.js
│   ├── dashboard.js
│   ├── products.js
│   ├── clients.js
│   ├── sales.js
│   ├── billing.js
│   ├── reports.js
│   ├── settings.js
│   └── api
│       └── auth.js
├── components
│   ├── Layout.js
│   ├── Navbar.js
│   ├── Sidebar.js
│   ├── Footer.js
│   ├── AuthForm.js
│   ├── DataTable.js
│   ├── FormComponents.js
│   └── DashboardWidgets.js
```

Total Files (excluding configuration and root files): Approximately 25 files.

## Core Functionalities

### 1. User Management and Roles (Security)

#### Objective
Ensure controlled and secure access to the application.

#### Key Features
- Authentication: User registration and login using Supabase Auth
- Roles and Permissions: Differentiate access levels (Administrator, Salesperson, Support)
- Password Recovery and Two-Factor Authentication: Utilize Supabase's built-in features
- UI Consistency: Integration with ShadCN for security and login interfaces

#### Implementation Details
- File: `pages/login.js`
- Component: `AuthForm.js` (located in `components/AuthForm.js`)
- Authentication Functions: Use supabase.auth methods for sign-up, sign-in, and session management

##### Examples

```javascript
// Sign-In Function
async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    console.error("Error signing in:", error.message);
  } else {
    console.log("User signed in successfully:", data);
  }
}

// Check User Session
async function getCurrentSession() {
  const { data: session, error } = await supabase.auth.getSession();

  if (error) {
    console.error("Error getting session:", error.message);
  } else {
    console.log("Current session:", session);
  }
}
```

#### Users Involved
Administrators and Salespersons

#### Success Metrics
- Secure access
- No unauthorized access
- Traceability of user actions

### 2. Products Module

#### Objective
Centralize and manage information about all products available for sale.

#### Key Features
- Product Catalog: Details like name, description, default unit price, unit of sale, and status
- Product Management: Ability to add, edit, or deactivate products
- Variable Pricing: Configuration per product or customer
- Product Categories: For easier organization and search
- UI Enhancements: Use of ShadCN and Lucide Icons

#### Implementation Details
- File: `pages/products.js`
- Components: Use `DataTable.js` and `FormComponents.js` for listing and managing products
- Database Interactions: Use `supabase.from('products')` for CRUD operations

##### Examples

```javascript
// Fetch Products
async function fetchProducts() {
  const { data, error } = await supabase.from('products').select('*');
  if (error) {
    console.error('Error fetching products:', error);
  } else {
    console.log('Products:', data);
  }
}

// Add Product
async function addProduct() {
  const { data, error } = await supabase
    .from('products')
    .insert([{ name: 'Test Product', description: 'A test product', price: 10 }])
    .select();

  if (error) {
    console.error('Error adding product:', error);
    return null;
  } else if (data && data.length > 0) {
    console.log('Product added:', data);
    return data[0].id;
  } else {
    console.error('No data returned after inserting product.');
    return null;
  }
}
```

#### Users Involved
Administrators

#### Success Metrics
- Accurate product information
- Ease of updating
- Seamless integration with the sales module

### 3. Clients Module

#### Objective
Maintain an organized client database for quick access to contact and purchase information.

#### Key Features
- Contact Details: Storage and editing of client information
- Purchase History: Detailed records for each client
- Client Segmentation: For targeted marketing efforts
- Communication Preferences: Manage preferred contact methods
- Special Pricing: Predefined prices for specific clients

#### Implementation Details
- File: `pages/clients.js`
- Components: Use `DataTable.js` and `FormComponents.js` for client management

#### Users Involved
Administrators and Salespersons

#### Success Metrics
- Completeness and accuracy of client data
- Up-to-date purchase history
- Effective client segmentation

### 4. Daily Sales Module

#### Objective
Register and manage daily sales with visualization of daily totals.

#### Key Features
- Sales Registration: Record details like date, client, product, quantity, unit price, and total
- Transaction Traceability: Link sales with corresponding products and clients
- Special Pricing Application: Automatic during sales registration
- Calculations: Automatic totals and averages, including taxes and discounts
- Corrections and Voids: With reason recording and administrator authorization
- Reports: Generate daily performance graphs and best-selling products

#### Implementation Details
- File: `pages/sales.js`
- Components: Use `DataTable.js`, `FormComponents.js`, and modals for sale entries
- Database Interactions: Use `supabase.from('sales')` for recording sales data

#### Users Involved
Salespersons and Administrators

#### Success Metrics
- Accurate daily records
- Achievement of sales targets
- Reduced manual entry errors
- Agility in error correction

### 5. Billing and Payments System

#### Objective
Automate invoice generation and manage payment statuses.

#### Key Features
- Invoice Generation: Automatic creation for each sale
- Payment Management: Record payments received or pending
- Overdue Reminders: Automatic notifications for unpaid invoices
- Billing History: Accessible and searchable by client, date, and payment status
- Accounting Integration: Export financial data for accounting purposes

#### Implementation Details
- File: `pages/billing.js`
- Components: Use `DataTable.js` and `FormComponents.js` for billing management
- Database Interactions: Use `supabase.from('invoices')` and `supabase.from('payments')`

#### Users Involved
Salespersons and Administrators

#### Success Metrics
- Billing accuracy
- Control of pending payments
- Customer satisfaction
- Reduction in unpaid invoices

### 6. Basic Indicators and Reports

#### Objective
Provide an overview of sales data and key indicators for decision-making.

#### Key Features
- Sales Totals and Averages: Daily, monthly, and annual breakdowns
- Sales Projections: Monthly projections with comparative charts
- Data Export: Backups in formats like Excel or PDF
- Performance Reports: Assess team effectiveness by salesperson

#### Implementation Details
- File: `pages/reports.js`
- Components: Use `DashboardWidgets.js` and chart libraries for data visualization
- Data Aggregation: Use Supabase functions or server-side calculations

#### Users Involved
Administrators

#### Success Metrics
- Ease of data interpretation
- Accuracy in projections
- Informed decision-making

### 7. Special Pricing and Discount Management

#### Objective
Offer personalized prices or discounts for specific clients.

#### Key Features
- Special Price Configuration: For frequent clients or campaigns with validity dates
- Automatic Discounts: For quantity or season, with configurable rules
- Discount Management: For selected products, with administrator approval
- Volume Discounts: Automatic reductions based on quantities

#### Implementation Details
- Integration: Functionality incorporated within `products.js`, `clients.js`, and `sales.js`
- Components: Use `FormComponents.js` for discount settings

#### Users Involved
Administrators

#### Success Metrics
- Increased sales
- Accuracy in discount application
- Effectiveness of promotional campaigns

### 8. Notifications and Alerts

#### Objective
Automate alerts for important events and deadlines.

#### Key Features
- Sales Notifications: For important sales or subscription expirations
- Payment Reminders: For overdue invoices via email or SMS
- Internal Alerts: For inactive clients or those with payment issues

#### Implementation Details
- Real-Time Features: Utilize Supabase's real-time subscriptions or scheduled functions
- Components: Notification components integrated within relevant pages

#### Users Involved
Administrators and Salespersons

#### Success Metrics
- Reduced missed tasks
- Increased efficiency
- Reduction in overdue payments

### 9. Visual Dashboard

#### Objective
Provide a visual dashboard for sales data analysis and performance tracking.

#### Key Features
- Graphs and Visualizations: For sales trends, recurring clients, and projections
- Real-Time Indicators: Display key metrics like daily sales and stock levels
- Interactive Filters: Customize dashboard views by time periods or categories

#### Implementation Details
- File: `pages/dashboard.js`
- Components: Use `DashboardWidgets.js` and chart libraries
- Data Fetching: Efficient data retrieval for performance

#### Users Involved
Administrators

#### Success Metrics
- Clear data representation
- Quick decision-making
- Customizable information display

### 10. Subscriptions and Planning

#### Objective
Manage recurring deliveries and automate billing for subscribed clients.

#### Key Features
- Subscription Configuration: Adjustable delivery frequency and quantities
- Automatic Invoicing: Generate invoices and reminders for renewals
- Subscription Management: Handle pauses or cancellations with retention strategies

#### Implementation Details
- Integration: Features within `clients.js` and `billing.js`
- Database: Use `supabase.from('subscriptions')` for subscription data

#### Users Involved
Administrators and Salespersons

#### Success Metrics
- Growth in subscriptions
- Accurate billing
- Reduced cancellations



### 11. Heatmap for Delivery Addresses

#### Objective
Visualize delivery zones as a heatmap to identify areas with high customer density and focus marketing strategies in those sectors.

#### Key Features
1. **Automatic Conversion of Addresses to Coordinates**:
   - Use a geocoding service to transform addresses into coordinates (latitude and longitude)
   - Store coordinates in the database for future analysis and visualizations

2. **Dynamic Heatmap Generation**:
   - Real-time visualization of delivery areas on an interactive map
   - Options to filter data by date, delivered products, or number of orders

3. **Integration with Existing Application**:
   - A dedicated module in the dashboard to access the heatmap
   - Leverage the current stack (**Next.js**, **Supabase**, **Tailwind CSS**) for seamless integration

#### Implementation Details

##### API Endpoint for Coordinates
```javascript
// pages/api/heatmap-data.js
import { supabase } from '@/lib/supabaseClient';

export default async function handler(req, res) {
  const { data, error } = await supabase.from('addresses').select('lat, lng');
  if (error) return res.status(500).json({ error: error.message });

  res.status(200).json(data);
}
```

##### Geocoding Implementation
```javascript
async function geocodeAddress(address) {
  const API_KEY = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${API_KEY}`;
  const response = await fetch(url);
  const data = await response.json();

  if (data.results.length > 0) {
    const { lat, lng } = data.results[0].geometry.location;
    return { lat, lng };
  }
  throw new Error('Geocoding failed');
}
```

##### Frontend Component
```javascript
import { useEffect } from 'react';
import L from 'leaflet';
import 'leaflet.heat';

const Heatmap = () => {
  useEffect(() => {
    const map = L.map('map').setView([-12.0464, -77.0428], 13);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(map);

    fetch('/api/heatmap-data')
      .then((res) => res.json())
      .then((data) => {
        const heatData = data.map((point) => [point.lat, point.lng]);
        L.heatLayer(heatData, { radius: 25 }).addTo(map);
      });
  }, []);

  return <div id="map" style={{ height: '500px' }}></div>;
};

export default Heatmap;
```

#### Workflow Integration
1. **Automatic Process**:
   - When a new address is added:
     - The geocoding script runs automatically
     - Coordinates are stored in the database
     - Data is dynamically updated in the heatmap

2. **Required APIs and Libraries**:
   - **Geocoding**: Google Maps Geocoding API
   - **Maps**: Leaflet.js and Leaflet.heat

#### Users Involved
Administrators

#### Success Metrics
- Identification of new marketing areas
- Improved efficiency of marketing campaigns
- Optimized delivery routes through geographic analysis


## Technical Documentation

### 1. Initial Project Setup

#### Initialize the Next.js Project
```bash
npx create-next-app@latest nevados-app
cd nevados-app
```

#### Install Dependencies

```bash
# Supabase Client
npm install @supabase/supabase-js

# Tailwind CSS and PostCSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# ShadCN UI Components
npm install @shadcn
```

### 2. Configure Supabase Client

File: `lib/supabaseClient.js`
```javascript
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseKey);
```

Environment Variables: Add to `.env.local`
```env
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 3. Setting Up Tailwind CSS

#### Tailwind Configuration: `tailwind.config.js`
```javascript
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
```

#### Global Styles: `styles/globals.css`
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### 4. Building Reusable UI Components

#### Components Directory: `components/`
- Layout Components: `Layout.js`, `Navbar.js`, `Sidebar.js`, `Footer.js`
- Form Components: `FormComponents.js` (input fields, buttons, selects)
- Data Display: `DataTable.js` for listing items
- Dashboard Elements: `DashboardWidgets.js` for the dashboard page

Example of a Reusable Button Component:

```javascript
// components/FormComponents.js
import { Button } from "@/components/ui/button"

export function Button({ children, className, ...props }) {
  return (
    <ShadButton className={`bg-blue-500 hover:bg-blue-600 ${className}`} {...props}>
      {children}
    </ShadButton>
  );
}
```

### 5. Database Operations with Supabase

#### CRUD Operations Example

##### Fetching Data
```javascript
// lib/utils.js
export async function fetchData(table) {
  const { data, error } = await supabase.from(table).select('*');
  if (error) {
    console.error(`Error fetching data from ${table}:`, error);
    return [];
  }
  return data;
}
```

##### Inserting Data
```javascript
export async function insertData(table, payload) {
  const { data, error } = await supabase.from(table).insert([payload]).select();
  if (error) {
    console.error(`Error inserting data into ${table}:`, error);
    return null;
  }
  return data;
}
```

##### Updating Data
```javascript
export async function updateData(table, id, updates) {
  const { data, error } = await supabase.from(table).update(updates).eq('id', id);
  if (error) {
    console.error(`Error updating data in ${table}:`, error);
    return null;
  }
  return data;
}
```

##### Deleting Data
```javascript
export async function deleteData(table, id) {
  const { data, error } = await supabase.from(table).delete().eq('id', id);
  if (error) {
    console.error(`Error deleting data from ${table}:`, error);
    return null;
  }
  return data;
}
```

### 6. Authentication Flow

#### Authentication Component: `components/AuthForm.js`
#### Session Management: Use React Context for global authentication state

Auth Context Example:

```javascript
// lib/AuthContext.js
import { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from './supabaseClient';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    const session = supabase.auth.session();
    setUser(session?.user ?? null);

    const { data: listener } = supabase.auth.onAuthStateChange((event, session) => {
      setUser(session?.user ?? null);
    });

    return () => {
      listener.unsubscribe();
    };
  }, []);

  return <AuthContext.Provider value={{ user }}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
```


## Development Guidelines

- **Code Reusability**: Utilize shared components to prevent code duplication
- **State Management**: Use React Context and custom hooks for global state
- **Error Handling**: Implement error boundaries and centralized error logging
- **Responsive Design**: Ensure UI components are responsive across devices
- **Accessibility**: Follow best practices to make the application accessible
- **Testing**: Write unit tests and integration tests where appropriate
- **Version Control**: Use Git for source control, with clear commit messages and branches

## Conclusion

This PRD provides a comprehensive guide for developers to implement the Nevados web application. By adhering to the outlined structure, utilizing the provided examples, and following best practices, the development team can build a robust, scalable, and efficient system that meets all the specified objectives and success metrics.