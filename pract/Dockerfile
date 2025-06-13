# Use the official Nginx image as base
FROM nginx:alpine

# Remove the default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy your application files into the nginx html directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Nginx will start automatically when the container runs
CMD ["nginx", "-g", "daemon off;"]