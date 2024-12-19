/** @type {import('next').NextConfig} */
const nextConfig = {
  compiler: {
    styledComponents: true
  },
  typescript: {
    // Enable strict type checking during development
    ignoreBuildErrors: false
  },
  eslint: {
    // Enable strict ESLint checking during development
    ignoreDuringBuilds: false
  }
}

module.exports = nextConfig