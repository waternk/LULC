
library(dismo)
library(gbm)
library(tcltk2)
library(randomForest)

source('train.test.data.r')

# Build BRT Models

# Workspace and parameters
drive <- 'z'
workspace <- paste(drive,':/LULC',sep='')
the.radii <- c(12070,24140) # 48280 # 24140
cell.size <- 250
ag.factors <- c(1,4) # 1 # 4
ver <- 6
no.backcast <- 'n'

# Test and training datasets
n <- 6822 # There are 6822 Records
# create.test.data(row.numbers=seq(1,n,1), proportion=0.2, file.name=paste(workspace,'/Models/gp.lulc.test.rows.v1.txt',sep=''))
test.rows <- scan(file=paste(workspace,'/Models/gp.lulc.test.rows.v1.txt',sep=''),what=numeric())
train.rows <- drop.test.rows(row.numbers=seq(1,n,1), test.rows=test.rows)

spp <- read.csv(paste('z:/lulc/gp_focal_spp_list_v',ver,'.csv',sep=''), stringsAsFactors=FALSE, row.names=1)

for (i in 1:21) # 1:11 # 12:21 # length(spp$BBL_ABBREV)) # max is 21
{
	for (n in 2) #1:2
	{
		for (j in 1:2) #1:2
		{
			the.radius <- the.radii[n]
			ag.factor <- ag.factors[j]
			species <- spp$BBL_ABBREV[i]
			if(file.exists(paste(workspace,'/Models/gp.lulc.brt.',ver,'.',species,'.r',the.radius,'m.',ag.factor*cell.size,'m.rdata',sep=''))==TRUE) { cat(the.radius,'\n'); next(j) }
			
			load(paste(workspace,'/Species/gp.lulc.',species,'.r',the.radius,'m.',ag.factor*cell.size,'m.rdata',sep=''))

			the.data <- pa.bird.data[train.rows,]
			if (no.backcast=='y') { the.data <- the.data[the.data$count_yr >= 92,] }
			# print(colnames(the.data)); print(dim(the.data)); stop('cbw')
			cat('\nnstart model,',species)
			cat(' points considered...',dim(the.data)[1],'\n')
			# print(table(the.data$how_many))
			
			# RF
			the.data$detect <- factor(the.data$detect, levels=c(0,1))
			rf.model <- randomForest(y=the.data$detect, x=the.data[,c(7,11:27)] , importance=TRUE)
			# print(rf.model)
			# print(rf.model$importance)
			save(rf.model,file=paste(workspace,'/Models/GreatPlains/Distribution/gp.lulc.rf.',ver,'.',species,'.r',the.radius,'m.', ag.factor*cell.size,'m.rdata',sep=''))
			
			# BRT
			# brt.model <- gbm.step(data=the.data, gbm.x=c(7,12:28), gbm.y=9, family="binomial", tree.complexity=spp$complexity[i], learning.rate=spp$learning.rate[i], bag.fraction=0.5, verbose=FALSE)
			# cat('# trees = ',brt.model$n.trees,'\n')
			# save(brt.model,file=paste(workspace,'/Models/GreatPlains/Abundance/gp.lulc.brt.',ver,'.',species,'.r',the.radius,'m.', ag.factor*cell.size,'m.rdata',sep=''))
					
			cat('\nend model',species,'############################\n')
			# stop('cbw')
		}
	}
}

