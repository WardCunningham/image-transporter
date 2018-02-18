# Image Transporter

This is a back-end scanning/scrapping application that operates in response to Transport plugins that
appear on federated wiki pages. The applicaton knows just enough federated wiki to offer up these pages
and then respond with more pages when interesting content is dropped on the former.

![image](https://cloud.githubusercontent.com/assets/12127/10421973/6ba29e34-7068-11e5-9cff-1551950a3566.png)

### Build
```
docker build -t image .
```

### Run
```
docker run -d -p 4010:4010 --restart always image
```
