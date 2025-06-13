# Use Amazon ECR Public Nginx image to avoid Docker Hub rate limits
FROM public.ecr.aws/nginx/nginx:alpine

# Remove the default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy your application files into the nginx html directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Nginx will start automatically when the container runs
CMD ["nginx", "-g", "daemon off;"]