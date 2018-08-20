#coding=utf-8
import torch
from torch.utils.data import DataLoader
from torchvision.datasets import MNIST
from torchvision import transforms
from torch import optim
from model.mlp import MLP
from function.quantize_weight_noise import quantize_weight,noise,store_param
import torch.nn as nn

'''
    在784*100*10的mlp中加入了，权重量化，IO量化和模拟的忆阻器噪音。
    :param _module: nn
    :param w_bits: 权重量化比特数
    :param io_bits: io量化比特数
    :param cells: cell数，只影响噪音大小，默认使用ADD方法
'''


learning_rate = 0.005
batch_size = 100
epoches = 100
w_bits=4
io_bits=4
cells=1
save_weight=False

trans_img = transforms.ToTensor()

trainset = MNIST('./data', train=True, transform=trans_img)
testset = MNIST('./data', train=False, transform=trans_img)

trainloader = DataLoader(trainset, batch_size=batch_size, shuffle=True, num_workers=4)
testloader = DataLoader(testset, batch_size=batch_size, shuffle=False, num_workers=4)

# build network

mnist_mlp = MLP(io_bits=io_bits)
mnist_mlp.cuda()
try:
    data=torch.load('mlp_mnist_nobias.t7')
    mnist_mlp.load_state_dict(data)
    print ('Loading weight')
except:
    print ('Initializing model')

#

##
criterian = nn.CrossEntropyLoss(size_average=False)
optimizer = optim.SGD(mnist_mlp.parameters(), lr=learning_rate)
best_acc=0

for i in range(epoches):
    #training
    running_acc = 0.
    for (img, label) in trainloader:
        img = torch.autograd.Variable(img).cuda()
        label = torch.autograd.Variable(label).cuda()
        save_param, st = quantize_weight(mnist_mlp, w_bits, cells)
        noise(mnist_mlp, st)
        optimizer.zero_grad()
        output = mnist_mlp(img)
        loss = criterian(output, label)
        loss.backward()
        optimizer.step()
        store_param(mnist_mlp, save_param)
    #testing
    save_param, st = quantize_weight(mnist_mlp, w_bits, cells)
    for (img, label) in testloader:
        noise(mnist_mlp, st)
        img = torch.autograd.Variable(img).cuda()
        label = torch.autograd.Variable(label).cuda()
        output = mnist_mlp(img)
        _, predict = torch.max(output, 1)
        correct_num = (predict == label).sum()
        running_acc += correct_num.data[0]
        store_param(mnist_mlp, save_param)
    running_acc /= len(testset)
    print (running_acc)
    if running_acc>best_acc:
        best_acc=running_acc
        if save_param:
            print ('saving')
            torch.save(mnist_mlp.state_dict(),'mlp_mnist.t7')
