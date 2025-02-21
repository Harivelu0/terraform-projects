/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'standalone',
  images: {
    domains: [
      'img.clerk.com',
      'images.clerk.dev'
    ],
  }
};

export default nextConfig;
