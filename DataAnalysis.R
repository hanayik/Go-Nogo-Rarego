# data analysis for GoNoGo task
library("sciplot")
library(Hmisc)
allConSubjAcc = c()
allConMedRT = c()
allConNumOfNoGos = c()
allConMissedTargs = c()
allConNumPers = c()
allConAdjRT = c()

allCussSubjAcc = c()
allCussMedRT = c()
allCussNumOfNoGos = c()
allCussMissedTargs = c()
allCussNumPers = c()
allCussAdjRT = c()

######################  con group   ######################################
baseFolder = "/Users/rorden/Documents/MATLAB/Go-Nogo-Rarego-master (3)/data/con"
fileList = list.files(baseFolder, pattern = ".csv", full.names = TRUE)
numberOfFiles = length(fileList)
for (i in 1:numberOfFiles) {
  file = fileList[i]
  data = read.csv(file)
  subjAcc = round(mean(data$accuracy)*100, digits = 2)
  nogoResp = length(data$trialType[data$trialType == "nogo" & data$subjResp == 1 & is.na(data$subjResp) == FALSE])
  numNogoTrials = length(data$trialType[data$trialType == "nogo"])
  nogoAcc = round(((25-nogoResp)/numNogoTrials)*100,digits=2)
  raregoMisses = length(data$trialType[data$trialType == "rarego" & data$accuracy == 0])
  goRT = round(mean(data$RT[data$trialType == "go" & data$RT < 999]),digits=2)
  rareGoRT = round(mean(data$RT[data$trialType == "rarego" & data$RT < 999]),digits=2)
  noGoRT = round(mean(data$RT[data$trialType == "nogo" & data$RT < 999 ]),digits=2)
  averageRT = round(mean(data$RT[data$RT < 999]),digits=2) 
  medianRT = round(median(data$RT[data$RT < 999]),digits=2) 
  AdjRT = round(median(data$RT[data$RT < 999 & data$RT > 0.1]),digits=2)
  numPers = length(data$RT[data$RT<0.1]) # perseverations are RT less than 100ms
  missedTargs = length(data$trialType[data$trialType != "nogo" & is.na(data$subjResp) == TRUE])
  
  allConSubjAcc = append(allConSubjAcc, subjAcc)
  allConMedRT = append(allConMedRT, medianRT)
  allConNumOfNoGos = append(allConNumOfNoGos, nogoResp)
  allConNumPers = append(allConNumPers, numPers)
  allConAdjRT = append(allConAdjRT, AdjRT)
  allConMissedTargs = append(allConMissedTargs, missedTargs)
}

dataForCard_zConGoNoGo = scale(allConSubjAcc)

######################  cuss group   ######################################
baseFolder = "/Users/rorden/Documents/MATLAB/Go-Nogo-Rarego-master (3)/data/cuss"
fileList = list.files(baseFolder, pattern = ".csv", full.names = TRUE)
numberOfFiles = length(fileList)
for (i in 1:numberOfFiles) {
  file = fileList[i]
  data = read.csv(file)
  subjAcc = round(mean(data$accuracy)*100, digits = 2)
  nogoResp = length(data$trialType[data$trialType == "nogo" & data$subjResp == 1 & is.na(data$subjResp) == FALSE])
  numNogoTrials = length(data$trialType[data$trialType == "nogo"])
  nogoAcc = round(((25-nogoResp)/numNogoTrials)*100,digits=2)
  raregoMisses = length(data$trialType[data$trialType == "rarego" & data$accuracy == 0])
  goRT = round(mean(data$RT[data$trialType == "go" & data$RT < 999]),digits=2)
  rareGoRT = round(mean(data$RT[data$trialType == "rarego" & data$RT < 999]),digits=2)
  noGoRT = round(mean(data$RT[data$trialType == "nogo" & data$RT < 999 ]),digits=2)
  averageRT = round(mean(data$RT[data$RT < 999]),digits=2) 
  medianRT = round(median(data$RT[data$RT < 999]),digits=2) 
  AdjRT = round(median(data$RT[data$RT < 999 & data$RT > 0.1]),digits=2)
  numPers = length(data$RT[data$RT<0.1]) # perseverations are RT less than 100ms
  missedTargs = length(data$trialType[data$trialType != "nogo" & is.na(data$subjResp) == TRUE])
  
  allCussSubjAcc = append(allCussSubjAcc, subjAcc)
  allCussMedRT = append(allCussMedRT, medianRT)
  allCussNumOfNoGos = append(allCussNumOfNoGos, nogoResp) # this is called comissions
  allCussNumPers = append(allCussNumPers, numPers)
  allCussAdjRT = append(allCussAdjRT, AdjRT)
  allCussMissedTargs = append(allCussMissedTargs, missedTargs)
  
}

dataForCard_zCussGoNoGo = scale(allCussSubjAcc)

t = t.test(allConSubjAcc, allCussSubjAcc, var.equal = TRUE)
t


t = t.test(allConMedRT, allCussMedRT, var.equal = TRUE)
t

t = t.test(allConNumOfNoGos, allCussNumOfNoGos, var.equal = TRUE)
t

t = t.test(allConNumPers, allCussNumPers, var.equal = TRUE)
t

t = t.test(allConAdjRT, allCussAdjRT, var.equal = TRUE)
t

t = t.test(allConMissedTargs, allCussMissedTargs, var.equal = TRUE)
t

mat4corr = matrix(c(allConNumOfNoGos, allConAdjRT),nrow=length(allConAdjRT))
print("Correlation of no gos and adj RT")
rcorr(mat4corr, type="pearson")

mat4corr = matrix(c(allCussNumOfNoGos, allCussAdjRT),nrow=length(allCussAdjRT))
print("Correlation of no gos and adj RT")
rcorr(mat4corr, type="pearson")

# barCenters = barplot(c(mean(allConSubjAcc), mean(allCussSubjAcc)),
#         main = "Subj Acc: Con vs. Cuss",
#         xlab = "Group",
#         ylim = c(0, 105))
# segments(barCenters, mean(allConSubjAcc) - se(allConSubjAcc) * 2, barCenters,
#          mean(allCussSubjAcc) + se(allCussSubjAcc) * 2, lwd = 1.5)
# arrows(barCenters, mean(allConSubjAcc) - se(allConSubjAcc) * 2, barCenters,
#        mean(allCussSubjAcc) + se(allCussSubjAcc) * 2, lwd = 1.5, angle = 90,
#        code = 3, length = 0.05)


