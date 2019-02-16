
filedata <- "dataset.zip"
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
directory <- ("Dataset")
#check if file already exists
if(!file.exists(filedata)) {
  download.file(url, filedata, mode = "wb")
}
#check if directory exists and unzip
if(!dir.exists(directory)) {
  unzip("dataset.zip", files = NULL, exdir = ".")
}
#open relevant libraries
library(dplyr)
library(data.table)
library(tidyr)
#read the data into dplyr tbls
subject_test <- tbl_df(read.table("UCI HAR Dataset/test/subject_test.txt")) #subject
X_test <- tbl_df(read.table("UCI HAR Dataset/test/X_test.txt"))
y_test <- tbl_df(read.table("UCI HAR Dataset/test/y_test.txt"))
subject_train <- tbl_df(read.table("UCI HAR Dataset/train/subject_train.txt")) #subject
X_train <- tbl_df(read.table("UCI HAR Dataset/train/X_train.txt"))
y_train <- tbl_df(read.table("UCI HAR Dataset/train/y_train.txt"))
activity_labels <- tbl_df(read.table("UCI HAR Dataset/activity_labels.txt"))
features <- tbl_df(read.table("UCI HAR Dataset/features.txt"))
#clearly name some vectors
setnames(activity_labels, names(activity_labels), c("activityNum", "activityName"))
setnames(features, names(features), c("featureNum", "featureName"))

#1) Merge the training and the test sets to create one data set
subject_data <- rbind(subject_train, subject_test) #combine subject training and test datasets
setnames(subject_data, "V1", "subject") #rename V1 to subject
activity_data <- rbind(y_train, y_test) #combine activity trainings and test datasets
setnames(activity_data, "V1", "activityNum") #rename V1 to activityNum
dataset <- rbind(X_train, X_test)#combine training and test data
colnames(dataset) <- features$featureName #vector of featureName is now rows in X_test + y_test
subject_activity <- cbind(subject_data, activity_data) #combine subject and activity data created above
dataset <- cbind(subject_activity, dataset) #add subject and activity data to xtrain and xtest data. Full dataset.

#2) Extracts only the measurements on the mean and standard deviation for each measurement.
#measurements on mean and std dev for each measurement in separate ds
meanstd <- grep("mean\\(\\)|std\\(\\)", features$featureName, value = TRUE) #separate mean and std from features
meanstd <- union(c("subject", "activityNum"), meanstd) #add subject and activityNum to the top of the char list?
dataset <- subset(dataset, select = meanstd) #subset dataset to only take what matches with meanstd vals

#3) Uses descriptive activity names to name the activities in the data set
#descriptive activity names
dataset <- merge(activity_labels, dataset, by = "activityNum", all.x = TRUE) %>% #add activity labels to dataset
  select(-activityNum)

#4) Appropriately labels the data set with descriptive variable names.
#descriptive variable names
names(dataset) <- gsub("std\\(\\)", "SD", names(dataset))
names(dataset) <- gsub("mean\\(\\)", "MEAN", names(dataset))
names(dataset) <- gsub("^t", "time", names(dataset)) #t in the first position
names(dataset) <- gsub("^f", "frequency", names(dataset))
names(dataset) <- gsub("Acc", "Accelerometer", names(dataset))
names(dataset) <- gsub("Gyro", "Gyroscope", names(dataset))
names(dataset) <- gsub("Mag", "Magnitude", names(dataset))
names(dataset) <- gsub("BodyBody", "Body", names(dataset))
names(dataset) <- gsub("-", "_", names(dataset))

#5) From the data set in step 4, creates a second, independent tidy data set with the average of each
#variable for each activity and each subject.
#average each variable for each activity and each subject
grouped_dataset <- dataset %>%
  group_by(subject, activityName) %>%
  summarize_all(mean)
write.table(grouped_dataset, file = "grouped_dataset_run_analysis.txt", row.names = FALSE)