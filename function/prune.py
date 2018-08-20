import torch
import torch.cuda
import torch.nn as nn
import torch.utils.data
from torch.autograd import Variable

def pruning(_module, pruning_coefficient,masks = []):
    """
    prune network , sort weight and get the threshold , prune the weight less than threshold, generate masks
    prune weights
    :param _module: nn.module, network parts to be pruned
    :param pruning_coefficient: float number
    :return masks: mask matrix, indicate which weights should be set to 0
    """
    if not isinstance(_module, nn.Module):
        print("_module should be nn.Module")
        return

    for param in _module.parameters():
        if len(param.size())>1:
            a = Variable(param.data).data
            b = torch.abs(a)
            n = int(b.view(-1).size()[0] * pruning_coefficient)
            threshold,_ = torch.topk(b.view(-1),n,dim=0,largest=False)
            threshold=threshold[-1]
            mask = torch.ones(a.size()).cuda()
            mask*=threshold
            mask=torch.gt(b,mask)
            mask=mask.type('torch.cuda.FloatTensor')
            masks.append(mask)
    return masks

def masking(_module, masks):
    """
    add mask to weights
    :param _module:
    :param masks:
    :param counter:
    :return counter:
    """

    counter=0
    for param in _module.parameters():
        if len(param.size()) > 1:
            param.data *= masks[counter]
            counter += 1
    return counter
