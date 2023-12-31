########################################################################################
# K-means clustering implementation for our motivating data set in programming language R
########################################################################################

#Step 1: Data preprocessing and set a seed to ensure reproducibility since the 
#initial cluster centers arerandomly chosen.
####################################################################

rm(list = objects())
library(tidyverse)
library(ggplot2)

#Step 1a: Use the set.seed() function to ensure that the initial random assignment of clusters are the same
set.seed(100) # the choice of the seed is not important, one can replace 100 with any other integer.

#Step 1b: Read the SportsCars.csv data into R and name this object SC:
SC <- read.csv('SportsCars.csv', sep = ";", header = TRUE)

#Step 1c: Define a new set of variables:
SC <- SC %>% mutate(x1 = log(weight/max_power),
                    x2 = log(max_power/cubic_capacity),
                    x3 = log(max_torque),
                    x4 = log(max_engine_speed),
                    x5 = log(cubic_capacity))

#Step 1d: Create the raw design matrix X_ raw:
X_raw <- SC %>% select(x1,x2,x3,x4,x5)

#Step 1e:  Standardize the raw design matrix Xraw by column
# means and column standard deviations :
X <- apply(X_raw,2,function(x) (x - mean(x))/sd(x))

###################################################################

#Step 2: Calculate again (for completeness) the PCA and add 
#the coordinates to the original dataset.

#Step 2a: Perform PCA for dimension reduction:
SVD <- svd(X)
PCs <- X %*% SVD$v 
colnames(PCs) <- names(c(v = 1:5))

#Step 2b: Add  thec PCs to the original sports car data
SC <- cbind(SC,PCs)
####################################################################

#Step 3: Consider a maximum number of K clusters and define objects 
#for loop over k = 1, ...,K clusters
####################################################################

#Step 3a: We set the maximum number of clusters K=10 and we will perform 
#K-means clustering for the data set X.
k_m <- 10 # maximum number of clusters  (exercise: look at more and
#justify why 10 is reasonable in this case).

#Step 3b: define objects for loop over K clusters:
k_average <- colMeans(X) # average columns
Centers <- list()

#Step 3c: Record the cluster assignment for each observation:
Classifier <- matrix(1, k_m, nrow(X)) 

#Step 3d: Total Within-Cluster Dissimilarity (TWCD)
TWCD <- rep(NA,k_m)
TWCD[1] <- sum(colSums(X^2)) # if there is only one cluster (no classification)

###################################################################

#Step 4: Use the for loop and the kmeans() function in R to 
#perform K-means clustering for k= 1, ...,K.
###################################################################

#Step 4a: Use the 'kmeans' function to run the K-means algorithm for 1:k_m clusters. The #first argument of kmeans is matrix X and its second argument is the number of clusters 'cl'. 
for(cl in 2:k_m){
  if(cl == 2){
    kmeansX <- kmeans(X, cl)	# for cl = 2, the cluster centers are randomly assigned
  }
  if(cl > 2){
    
    #Step 4b: For cl > 2, the previous cluster centers plus 'k_average'
    # will be used as initial cluster centers:
    kmeansX <- kmeans(X, cluster_centers)
  }
  
  #Step 4c: Update the TWCD and record the results:
  TWCD[cl] <- sum(kmeansX$withins)  #The vector of within-cluster sum of squares
  Classifier[cl, ] <- kmeansX$cluster #A vector of integers (from 1:k) indicating the    
  #cluster to which each point is allocated.
  Centers[[cl]] <- kmeansX$centers   #A matrix of cluster centres.
  
  
  #Step 4c: Set up the initial cluster centers for the next loop
  cluster_centers <- matrix(NA, cl + 1, ncol(X))
  cluster_centers[cl + 1, ] <- k_average
  cluster_centers[1:cl, ] <- kmeansX$centers
}  
##################################################################

#Step 5: Plot the total Within Cluster Dissimilarity (TWCD) to observe how it 
#changes with respect to the total number of clusters.
###################################################################

#Step 5a: Use ggplot for the graph of TWCD vs the total number of clusters:

ggplot(data.frame(x = c(1:k_m), y = TWCD), aes(x = x, y = y)) +
  geom_point(size = 2, colour = "blue") +
  geom_line(linetype = 3, colour = "blue") +
  labs(x = "hyperparameter K", y = "total within-cluster dissimilarity",
       title ="Decrease in total within-cluster dissimilarity") +
  coord_cartesian(ylim = c(0, max(TWCD))) +
  scale_x_continuous(breaks = 1:k_m) 


#When we analyze the graph (elbow method) we can see that the graph will rapidly change from 4 to 5 creating an elbow shape. 
#Step 5b: The optimal number of clusters is 4.
cl_opt <- 4

#################################################################

#Step 6: Check the characteristics of the cl_opt<-4 clusters
#################################################################
# Step 6a: Use the function table and Classifier from Step 4 to  
#find the number of observations in each of the cl_opt<-4 clusters:
table(Classifier[cl_opt,])

#Step 6b: Use Centers from Step 4 to find the centers 
#of the cl_opt<-4 clusters:
Centers[[cl_opt]]

##################################################################

#Step 7: Create a table for summarizing the K-means clustering 
#results w.r.t. sports cars (expert judgment) for K = 4. 
###################################################################
#Step 7a: Type of cars:
SC <- SC %>% mutate(sports_type = cut(tau,breaks = c(0,17,21,100),
                                      labels = c("tau <17 ( sports car )","17 <= tau <21 ", "tau >=21 ")))

#Step 7b: Add the clusters to the sports car data set:
SC <- SC %>% mutate(cluster = factor(Classifier[cl_opt,]))

#Step 7c: Compute the number of cars per car type in each cluster:
SC %>% group_by(sports_type,cluster) %>% summarise(Count = n())

###################################################################

#Step 8: We will plot a graph to illustrate the four clusters on the first 
#two principal component axesfrom the PCA.
###################################################################
#Step 8a:  Cluster centers coordinates in first two principal components coordinates
Centers_pcs <- Centers[[cl_opt]] %*% SVD$v
colnames(Centers_pcs) <- names(c(x = 1:5)) 

#Step 8b: Use the first two columns, PCs, and show the cluster centers in black:
ggplot(SC, aes(x = v1, y = v2, colour = cluster)) + geom_point() +
  coord_cartesian(xlim = c(-6, 6),
                  ylim = c(-6, 6)) +
  labs(y = paste("principal component ", 2, sep = ""),
       x = paste("principal component ", 1, sep = ""),
       title = "K-means vs. PCA") +
  geom_point(data = data.frame(Centers_pcs),
             aes(x = x1, y = x2),
             size = 4,
             colour = "black")

########################################################################################
# K-medoids clustering implementation for our motivating data set in programming language R
########################################################################################

#Step 1: Install and load the 'cluster' package: 
library(cluster)

#Step 2: As the initial cluster centers are randomly chosen,
# a seed needs to be set to ensure reproducibility.
set.seed(100)

#Step 3: We will use cl_opt<-4 clusters 
#Note 1: Type in ?pam to have access to the online documentation 
#which describes the arguments of the pam() function.  
#Note 2: The manhattan distances are the sum of absolute differences
kmed <- pam(X, k = cl_opt, metric = "manhattan", diss = FALSE) # number of clusters

#Step 4a: Find the number of observations in each cluster:
table(kmed$clustering)

#Step 4b: Find the medoid points. 
#It is a matrix with in each row the coordinates of one medoid.

kmed$medoids

#Step 4c: Find the integer vector of indices giving 
#the medoid observation numbers
SC[kmed$id.med,]

#Step 5a: Add the cluster labels to the data 
SC <- SC %>% mutate(cluster2 = factor(kmed$clustering))

#Step 5b: Find the number of sports cars per cluster:
SC %>% group_by(sports_type,cluster2) %>% summarise(count= n())

#Step 6a: Medoids  coordinates in first  two  principal  components coordinates:
kmed_medoids_pcs <- kmed$medoids %*% SVD$v
colnames(kmed_medoids_pcs) <- names(c(x=1:5))

#Step 6b: Use the  first  two  columns , PCs , and  show  the  cluster  centers  inblack:
ggplot(SC, aes(x = v1, y = v2, colour = cluster2)) + geom_point() +
  coord_cartesian(xlim = c(-6, 6),
                  ylim = c(-6, 6)) +
  labs(y = paste("principal component ", 2, sep = ""),
       x = paste("principal component ", 1, sep = ""),
       title = "K-means vs. PCA") +
  geom_point(data = data.frame(kmed_medoids_pcs),
             aes(x = x1, y = x2),
             size = 4,
             colour = "black")

