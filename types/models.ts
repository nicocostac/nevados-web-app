export interface Product {
  id: string;
  name: string;
  description: string;
  unit_of_sale: string;
  created_at?: string;
  updated_at?: string;
}

export interface BundleItem {
  product_id: string;
  quantity: number;
  product: Product;
  bundle_id?: string;
  created_at?: string;
  updated_at?: string;
}

export interface Bundle {
  id: string;
  name: string;
  description: string;
  total_price: number;
  status: string;
  start_date: string;
  end_date: string | null;
  items: BundleItem[];
  created_at?: string;
  updated_at?: string;
}

export interface Client {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  borough?: string;
  neighborhood?: string;
  latitude?: number;
  longitude?: number;
  created_at?: string;
  updated_at?: string;
}

export interface Sale {
  id: string;
  client_id: string;
  sale_date: string;
  delivery_date: string;
  status: string;
  total_amount: number;
  created_at?: string;
  updated_at?: string;
  client?: Client;
  items?: SaleItem[];
}

export interface SaleItem {
  id: string;
  sale_id: string;
  product_id: string;
  quantity: number;
  price: number;
  created_at?: string;
  updated_at?: string;
  product?: Product;
}

export interface Price {
  id: string;
  product_id: string;
  client_id?: string;
  price: number;
  min_quantity?: number;
  start_date: string;
  end_date?: string | null;
  created_at?: string;
  updated_at?: string;
  product?: Product;
  client?: Client;
}
