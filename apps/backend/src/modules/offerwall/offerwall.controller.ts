import {
  Body,
  Controller,
  Get,
  Headers,
  Post,
  Query,
  Req,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { getClientIp } from '../../common/utils/request.util';
import { GetOffersDto } from './dto/get-offers.dto';
import { OfferwallPostbackDto } from './dto/postback.dto';
import { OfferwallService } from './offerwall.service';

@ApiTags('offerwall')
@Controller('offerwall')
export class OfferwallController {
  constructor(private readonly offerwallService: OfferwallService) {}

  @Get()
  getOffers(@Query() dto: GetOffersDto, @Req() request: Request) {
    return this.offerwallService.getOffers(dto, getClientIp(request));
  }

  @Post('postback')
  postback(
    @Body() dto: OfferwallPostbackDto,
    @Headers('x-offerwall-signature') signature: string | undefined,
    @Req() request: Request,
  ) {
    return this.offerwallService.handlePostback(dto, signature, getClientIp(request));
  }

  @Get('postback/mylead')
  myLeadPostbackGet(
    @Query() query: Record<string, string | undefined>,
    @Req() request: Request,
  ) {
    return this.offerwallService.handleMyLeadPostback(query, getClientIp(request));
  }

  @Post('postback/mylead')
  myLeadPostbackPost(
    @Body() body: Record<string, string | number | undefined>,
    @Query() query: Record<string, string | undefined>,
    @Req() request: Request,
  ) {
    return this.offerwallService.handleMyLeadPostback({ ...query, ...body }, getClientIp(request));
  }
}
