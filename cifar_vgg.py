#coding=utf-8
from torch.autograd import Variable
import torchvision
import argparse
import torch
from model.cifar import VGG
from function.prune import pruning, masking
from function.quantize_weight_noise import quantize_weight, noise, store_param
import torch.nn as nn
import torch.optim as optim
import torch.backends.cudnn as cudnn
import numpy
import time

'''
    一个类似VGG结构的CNN，对cifar-10进行分类。
    加入了权重量化，IO量化，剪枝和模拟的忆阻器噪音。
    在训练中逐步的加入限制，来保证模型在训练中手链
    :param _module: nn
    :param w_bits: 权重量化比特数
    :param io_bits: io量化比特数
    :param cells: cell数，只影响噪音大小，默认使用ADD方法
    :param prune_rate: 剪枝率，越大强制置零的权重越多
'''


learning_rate = 0.0001
batch = 100
epoches = 100
w_bits = 5
io_bits = 0
cells = 1
prune_rate=0.5
save_weight = False

use_cuda = torch.cuda.is_available() # whether cuda is available
best_acc = 0  # best test accuracy
start_epoch = 0  # start from epoch 0 or last checkpoint epoch
parser = argparse.ArgumentParser(description='PyTorch CIFAR Example')
parser.add_argument('--lr', type=float, default=learning_rate, metavar='LR')
args = parser.parse_args()

# preprocess data set.
trainset = torchvision.datasets.CIFAR10(root='./data', train=True, download=True)
x = trainset.train_data
y = trainset.train_labels
x = numpy.asarray(x, dtype=float)
x = x.reshape(-1, 32, 32, 3)
x = x.transpose(0, 3, 1, 2)
x_train = torch.FloatTensor(x)
y_train = torch.LongTensor(y)

testset = torchvision.datasets.CIFAR10(root='./data', train=False, download=True)
x = testset.test_data
y = testset.test_labels
x = numpy.asarray(x, dtype=float)
x = x.reshape(-1, 32, 32, 3)
x = x.transpose(0, 3, 1, 2)
x_test = torch.FloatTensor(x)
y_test = torch.LongTensor(y)

net = VGG(iobit=io_bits)
try:
    data = torch.load('cifar_vgg.t7')
    net.load_state_dict(data)
    print ('Loading weight')
except:
    print ('Initializing model')

optimizer = optim.SGD(net.parameters(), lr=args.lr, momentum=0.9, weight_decay=5e-4)
#Multiple GPU
if use_cuda:
    net.cuda()
    net = torch.nn.DataParallel(net, device_ids=range(torch.cuda.device_count()))
    cudnn.benchmark = True

criterion = nn.CrossEntropyLoss()
start = time.time()

for epoch in range(epoches):
    print'\nEpoch: %d ' % epoch,
    for iter in range(y_train.size()[0] / batch):
        save_param, st = quantize_weight(net, w_bits, cells)# quantize weight and save oragin weight
        masks = pruning(net, prune_rate)# generate mask
        masking(net, masks)# do mask
        noise(net,st)#generate noise
        net.train()
        x_batch = x_train[iter * batch:(iter + 1) * batch]
        y_batch = y_train[iter * batch:(iter + 1) * batch]
        inputs = x_batch.cuda()
        targets = y_batch.cuda()
        optimizer.zero_grad()
        inputs, targets = Variable(inputs), Variable(targets)
        outputs = net(inputs)
        loss = criterion(outputs, targets)
        store_param(net, save_param)#restore weight
        loss.backward()
        optimizer.step()
        _, predicted = torch.max(outputs.data, 1)

    correct = 0
    total = 0
    masks = pruning(net, prune_rate)
    masking(net, masks)
    save_param, st = quantize_weight(net, w_bits, cells)
    for iter in range(y_test.size()[0] / batch):
        net.eval()
        noise(net,st)
        x_batch = x_test[iter * batch:(iter + 1) * batch]
        y_batch = y_test[iter * batch:(iter + 1) * batch]
        inputs = x_batch.cuda()
        targets = y_batch.cuda()
        inputs, targets = Variable(inputs), Variable(targets)
        outputs = net(inputs)
        _, predicted = torch.max(outputs.data, 1)
        total += targets.size(0)
        correct += predicted.eq(targets.data).cpu().sum()
        store_param(net, save_param)
    print ('cifar_vgg, %i, %i , %.2f ' % (w_bits, io_bits, (100. * correct / total)))

    if 100. * correct / total > best_acc:
        best_acc = correct / total
        if save_weight:
            print ('saving')
            torch.save(net.module.state_dict(), 'cifar_vgg.t7')
