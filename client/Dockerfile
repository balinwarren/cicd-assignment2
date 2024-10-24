# Use an official Nginx image as the base image
FROM nginx:alpine

# Set the working directory in the container
WORKDIR /usr/share/nginx/html

#Remove the default Nginx static files
RUN rm -rf ./*

# Copy the frontend files from your local machine to the container
COPY . /usr/share/nginx/html

# Expose port 80 (the default Nginx port)
EXPOSE 80

# Command to run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
