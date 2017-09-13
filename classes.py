import numpy

class stdevs:
    def __init__(self):
        self.list = []
        self.x = 0
    def step(self, value):
        if value != None:
            self.list.append(value)
    def finalize(self):
        #print(self.list)
        if len(self.list) > 1:
            self.x = numpy.std(self.list, ddof=1)
        else:
            self.x = None
        return self.x

class stdevp:
    def __init__(self):
        self.list = []
        self.x = 0
    def step(self, value):
        if value != None:
            self.list.append(value)
    def finalize(self):
        #print(self.list)
        if len(self.list) > 1:
            self.x = numpy.std(self.list, ddof=0)
        else:
            self.x = None
        return self.x

class meanw:
    def __init__(self):
        self.wgtlist = []
        self.list = []
        self.x = 0
    def step(self, value, wgt):
        if wgt == None:
            wgt = 1
        if value != None:
            self.list.append(value)
            self.wgtlist.append(wgt)
    def finalize(self):
        #print(self.list)
        if len(self.list) >= 1:
            y = numpy.array(self.list)
            w = numpy.array(self.wgtlist)
            self.x = (numpy.sum(w*y))/(numpy.sum(w))
        else:
            self.x = None
        return self.x

class stdevw:
    def __init__(self):
        self.wgtlist = []
        self.list = []
        self.x = 0
    def step(self, value, wgt):
        if wgt == None:
            wgt = 1
        if value != None:
            self.list.append(value*wgt)
            self.wgtlist.append(wgt)
    def finalize(self):
        #print(self.list)
        if len(self.list) > 1:
            #unbiased estimator of variance with sample weights
            #https://www.gnu.org/software/gsl/manual/html_node/Weighted-Samples.html
            #https://en.wikipedia.org/wiki/Weighted_arithmetic_mean   ###Reliability weights
            y = numpy.array(self.list)
            w = numpy.array(self.wgtlist)
            V1 = numpy.sum(w)
            V2 = numpy.sum(w**2)
            mu = (numpy.sum(w*y)/V1)
            muArray = numpy.full(y.size, mu)
            sigma2w = numpy.sum(w*((y-muArray)**2))
            self.x = (sigma2w/(V1-(V2/V1)))**(0.5)
        else:
            self.x = None
        return self.x
