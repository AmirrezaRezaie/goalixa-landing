# Basic static site image
FROM nginx:alpine

# Remove default site
RUN rm /usr/share/nginx/html/*

# Copy landing files
COPY index.html style.css script.js /usr/share/nginx/html/
COPY assets /usr/share/nginx/html/assets

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
